/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Subscribed and Unsubscribed callback typedefs
typedef SubscribeCallback = void Function(String topic);
typedef SubscribeFailCallback = void Function(String topic);
typedef UnsubscribeCallback = void Function(String topic);

/// A class that manages the topic subscription process.
class MqttSubscriptionManager {
  ///  Creates a new instance of a SubscriptionsManager that uses the
  ///  specified connection to manage subscriptions.
  MqttSubscriptionManager(this._connectionHandler, this._clientEventBus) {
    _connectionHandler.registerForMessage(
        MqttMessageType.subscribeAck, confirmSubscription);
    _connectionHandler.registerForMessage(
        MqttMessageType.unsubscribeAck, confirmUnsubscribe);
    // Start listening for published messages
    _clientEventBus.on<MqttMessageReceived>().listen(publishMessageReceived);
  }

  final _messageIdentifierDispenser = MqttMessageIdentifierDispenser();

  /// Dispenser used for keeping track of subscription ids
  MqttMessageIdentifierDispenser get messageIdentifierDispenser =>
      _messageIdentifierDispenser;

  final _subscriptions = <String, MqttSubscription>{};

  /// List of confirmed subscriptions, keyed on the topic name.
  Map<String, MqttSubscription> get subscriptions => _subscriptions;

  final _pendingSubscriptions = <int, List<MqttSubscription>>{};

  /// A list of subscriptions that are pending acknowledgement, keyed
  /// on the message identifier.
  Map<int, List<MqttSubscription>> get pendingSubscriptions =>
      _pendingSubscriptions;

  final _pendingUnsubscriptions = <int, String>{};

  /// A list of unsubscribe requests waiting for an unsubscribe ack message.
  /// Index is the message identifier of the unsubscribe message
  Map<int, String> get pendingUnsubscriptions => _pendingUnsubscriptions;

  /// The connection handler that we use to subscribe to subscription
  /// acknowledgements.
  final _connectionHandler;

  /// Subscribe and Unsubscribe callbacks
  SubscribeCallback onSubscribed;

  /// Unsubscribed
  UnsubscribeCallback onUnsubscribed;

  /// Subscription failed callback
  SubscribeFailCallback onSubscribeFail;

  /// The event bus
  final events.EventBus _clientEventBus;

  /// Observable change notifier for all subscribed topics
  final observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>
      _subscriptionNotifier =
      observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>();

  /// Subscription notifier
  observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>
      get subscriptionNotifier => _subscriptionNotifier;

  /// Registers a new subscription with the subscription manager.
  MqttSubscription registerSubscription(String topic, MqttQos qos) {
    var cn = _tryGetExistingSubscription(topic);
    return cn ??= _createNewSubscription(topic, qos);
  }

  /// Registers a new prebuilt subscription with the subscription manager.
  /// Note the message identifier of the subscription, if set, will be overwritten by
  /// this method.
  void registerPrebuiltSubscription(MqttSubscribeMessage message) {
    if (message.isValid) {
      _createNewPrebuiltSubscription(message);
    } else {
      throw ArgumentError(
          'MqttSubscriptionManager::registerPrebuiltSubscription - subscription is invalid');
    }
  }

  /// Gets a view on the existing observable, if the subscription
  /// already exists.
  MqttSubscription _tryGetExistingSubscription(String topic) {
    final retSub = subscriptions[topic];
    if (retSub == null) {
      // Search the pending subscriptions
      for (final subList in pendingSubscriptions.values) {
        for (final sub in subList) {
          if (sub.topic.rawTopic == topic) {
            return sub;
          }
        }
      }
    }
    return retSub;
  }

  /// Creates a new subscription for the specified topic and Qos.
  /// If the subscription cannot be created null is returned.
  MqttSubscription _createNewSubscription(String topic, MqttQos qos) {
    try {
      final subscriptionTopic = MqttSubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final msgId = messageIdentifierDispenser.getNextMessageIdentifier();
      final sub = MqttSubscription.withMaximumQos(subscriptionTopic, qos);
      pendingSubscriptions[msgId].add(sub);
      // Build a subscribe message for the caller and send it off to the broker.
      final msg =
          MqttSubscribeMessage().toTopicWithQos(sub.topic.rawTopic, qos);
      msg.messageIdentifier = msgId;
      _connectionHandler.sendMessage(msg);
      return sub;
    } on Exception catch (e) {
      MqttLogger.log('MqttSubscriptionManager::createNewSubscription '
          'exception raised, text is $e');
      if (onSubscribeFail != null) {
        onSubscribeFail(topic);
      }
      return null;
    }
  }

  /// Creates a new prebuilt subscription for the specified subscription message.
  void _createNewPrebuiltSubscription(MqttSubscribeMessage message) {
    try {
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final msgId = messageIdentifierDispenser.getNextMessageIdentifier();
      message.messageIdentifier = msgId;
      for (final subscription in message.payload.subscriptions) {
        final sub = MqttSubscription.withMaximumQos(
            subscription.topic, subscription.option.maximumQos);
        pendingSubscriptions[msgId].add(sub);
      }
      // Send the subscribe message to the broker.
      _connectionHandler.sendMessage(message);
    } on Exception catch (e) {
      MqttLogger.log('MqttSubscriptionManager::_createNewPrebuiltSubscription '
          'exception raised, text is $e');
      if (onSubscribeFail != null) {
        onSubscribeFail('prebuilt no topic');
      }
      return null;
    }
  }

  /// Publish message received
  void publishMessageReceived(MqttMessageReceived event) {
    final topic = event.topic;
    final msg = MqttReceivedMessage<MqttMessage>(topic.rawTopic, event.message);
    subscriptionNotifier.notifyChange(msg);
  }

  /// Unsubscribe from a topic
  void unsubscribe(String topic) {
    final unsubscribeMsg = MqttUnsubscribeMessage()
        .withMessageIdentifier(
            messageIdentifierDispenser.getNextMessageIdentifier())
        .fromStringTopic(topic);
    _connectionHandler.sendMessage(unsubscribeMsg);
    pendingUnsubscriptions[unsubscribeMsg.variableHeader.messageIdentifier] =
        topic;
  }

  /// Confirms a subscription has been made with the broker.
  /// Marks the sub as confirmed in the subs storage.
  /// Returns true on successful subscription, false on fail.
  /// Note if any subscriptions fail a fail will be returned.
  bool confirmSubscription(MqttMessage msg) {
    final MqttSubscribeAckMessage subAck = msg;
    final reasonCodes = subAck.reasonCodes;
    var ok = true;
    var reasonCodeIndex = 0;
    if (pendingSubscriptions
        .containsKey(subAck.variableHeader.messageIdentifier)) {
      for (final pendingTopic
          in pendingSubscriptions[subAck.variableHeader.messageIdentifier]) {
        final topic = pendingTopic.topic.rawTopic;
        // Check for a successful subscribe
        if (!MqttReasonCodeUtilities.isError(
            mqttSubscribeReasonCode.asInt(reasonCodes[reasonCodeIndex]))) {
          subscriptions[topic] = pendingTopic;
          if (onSubscribed != null) {
            onSubscribed(topic);
          }
        } else {
          subscriptions.remove(topic);
          if (onSubscribeFail != null) {
            onSubscribeFail(topic);
          }
          ok = false;
        }
        reasonCodeIndex++;
      }
      pendingSubscriptions.remove(subAck.variableHeader.messageIdentifier);
    } else {
      return false;
    }

    return ok;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage msg) {
    final MqttUnsubscribeAckMessage unSubAck = msg;
    final topic =
        pendingUnsubscriptions[unSubAck.variableHeader.messageIdentifier];
    subscriptions.remove(topic);
    pendingUnsubscriptions.remove(unSubAck.variableHeader.messageIdentifier);
    if (onUnsubscribed != null) {
      onUnsubscribed(topic);
    }
    return true;
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) {
    var status = MqttSubscriptionStatus.doesNotExist;
    if (subscriptions.containsKey(topic)) {
      status = MqttSubscriptionStatus.active;
    }
    for (final topics in pendingSubscriptions.values) {
      for (final subTopic in topics) {
        if (subTopic.topic.rawTopic == topic) {
          status = MqttSubscriptionStatus.pending;
        }
      }
    }
    return status;
  }
}
