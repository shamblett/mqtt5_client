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

/// A class that can manage the topic subscription process.
class MqttSubscriptionManager {
  ///  Creates a new instance of a SubscriptionsManager that uses the
  ///  specified connection to manage subscriptions.
  MqttSubscriptionManager(
      this.connectionHandler, this.publishingManager, this._clientEventBus) {
    connectionHandler.registerForMessage(
        MqttMessageType.subscribeAck, confirmSubscription);
    connectionHandler.registerForMessage(
        MqttMessageType.unsubscribeAck, confirmUnsubscribe);
    // Start listening for published messages
    _clientEventBus.on<MqttMessageReceived>().listen(publishMessageReceived);
  }

  /// Dispenser used for keeping track of subscription ids
  MqttMessageIdentifierDispenser messageIdentifierDispenser =
      MqttMessageIdentifierDispenser();

  /// List of confirmed subscriptions, keyed on the topic name.
  Map<String, MqttSubscription> subscriptions = <String, MqttSubscription>{};

  /// A list of subscriptions that are pending acknowledgement, keyed
  /// on the message identifier.
  Map<int, MqttSubscription> pendingSubscriptions = <int, MqttSubscription>{};

  /// A list of unsubscribe requests waiting for an unsubscribe ack message.
  /// Index is the message identifier of the unsubscribe message
  Map<int, String> pendingUnsubscriptions = <int, String>{};

  /// The connection handler that we use to subscribe to subscription
  /// acknowledgements.
  MqttIConnectionHandler connectionHandler;

  /// Publishing manager used for passing on published messages to subscribers.
  MqttPublishingManager publishingManager;

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
    var cn = tryGetExistingSubscription(topic);
    return cn ??= createNewSubscription(topic, qos);
  }

  /// Registers a new prebuilt subscription with the subscription manager.
  MqttSubscription registerPrebuiltSubscription(MqttSubscribeMessage message) {
    if (message.isValid) {
      var cn = tryGetExistingSubscription(
          message.payload.subscriptions[0].topic.rawTopic);
      return cn ??= createNewSubscription(
          message.payload.subscriptions[0].topic.rawTopic,
          message.payload.subscriptions[0].option.maximumQos);
    } else {
      throw ArgumentError(
          'SubscriptionsManager::registerPrebuiltSubscription - subscription is invalid');
    }
  }

  /// Gets a view on the existing observable, if the subscription
  /// already exists.
  MqttSubscription tryGetExistingSubscription(String topic) {
    final retSub = subscriptions[topic];
    if (retSub == null) {
      // Search the pending subscriptions
      for (final sub in pendingSubscriptions.values) {
        if (sub.topic.rawTopic == topic) {
          return sub;
        }
      }
    }
    return retSub;
  }

  /// Creates a new subscription for the specified topic.
  /// If the subscription cannot be created null is returned.
  MqttSubscription createNewSubscription(String topic, MqttQos qos) {
    try {
      final subscriptionTopic = MqttSubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final msgId = messageIdentifierDispenser.getNextMessageIdentifier();
      final sub = MqttSubscription();
      sub.topic = subscriptionTopic;
      sub.qos = qos;
      sub.messageIdentifier = msgId;
      sub.createdTime = DateTime.now();
      pendingSubscriptions[sub.messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final msg =
          MqttSubscribeMessage().toTopicWithQos(sub.topic.rawTopic, qos);
      connectionHandler.sendMessage(msg);
      return sub;
    } on Exception catch (e) {
      MqttLogger.log('Subscriptionsmanager::createNewSubscription '
          'exception raised, text is $e');
      if (onSubscribeFail != null) {
        onSubscribeFail(topic);
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
    connectionHandler.sendMessage(unsubscribeMsg);
    pendingUnsubscriptions[unsubscribeMsg.variableHeader.messageIdentifier] =
        topic;
  }

  /// Confirms a subscription has been made with the broker.
  /// Marks the sub as confirmed in the subs storage.
  /// Returns true on successful subscription, false on fail.
  bool confirmSubscription(MqttMessage msg) {
    final MqttSubscribeAckMessage subAck = msg;
    String topic;
    if (pendingSubscriptions
        .containsKey(subAck.variableHeader.messageIdentifier)) {
      topic = pendingSubscriptions[subAck.variableHeader.messageIdentifier]
          .topic
          .rawTopic;
      subscriptions[topic] =
          pendingSubscriptions[subAck.variableHeader.messageIdentifier];
      pendingSubscriptions.remove(subAck.variableHeader.messageIdentifier);
    } else {
      return false;
    }

    // Check the Qos, we can get a failure indication(value 0x80) here if the
    // topic cannot be subscribed to.
    // TODO
//    if (subAck.payload.qosGrants[0] == MqttQos.failure) {
//      subscriptions.remove(topic);
//      if (onSubscribeFail != null) {
//        onSubscribeFail(topic);
//        return false;
//      }
//    }
    // Success, call the subscribed callback
    if (onSubscribed != null) {
      onSubscribed(topic);
    }
    return true;
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
    pendingSubscriptions.forEach((int key, MqttSubscription value) {
      if (value.topic.rawTopic == topic) {
        status = MqttSubscriptionStatus.pending;
      }
    });
    return status;
  }
}
