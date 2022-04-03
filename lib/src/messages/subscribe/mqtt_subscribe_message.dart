/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The subscribe message is sent from the client to the broker to create one or more subscriptions.
/// Each subscription registers the client’s interest in one or more topics.
/// The broker sends publish messagesto the client to forward application messages
/// that were published to topics that match these subscriptions.
///
/// The subscribe message also specifies (for each subscription) the maximum QoS with
/// which the broker can send application messages to the client.
class MqttSubscribeMessage extends MqttMessage {
  /// Initializes a new instance of the MqttSubscribeMessage class.
  MqttSubscribeMessage() {
    header = MqttHeader().asType(MqttMessageType.subscribe);
    // Qos at least once must be set for a subscribe message
    header!.qos = MqttQos.atLeastOnce;
    _variableHeader = MqttSubscribeVariableHeader();
    _payload = MqttSubscribePayload();
  }

  MqttSubscribeVariableHeader? _variableHeader;

  /// Gets the variable header contents.
  MqttSubscribeVariableHeader? get variableHeader => _variableHeader;

  MqttSubscribePayload? _payload;

  /// Gets the payload contents.
  MqttSubscribePayload? get payload => _payload;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    if (!isValid) {
      return;
    }
    header!.writeTo(
        variableHeader!.getWriteLength() + payload!.getWriteLength(),
        messageStream);
    variableHeader!.writeTo(messageStream);
    payload!.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  /// Not implemented, message is send only.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    throw UnimplementedError(
        'MqttSubscribeMessage::readFrom - not implemented, message is send only');
  }

  /// Is valid, if not valid the subscription message cannot be sent to
  /// the broker. At least one topic must be present in the payload and the
  /// message identifier must be set.
  @override
  bool get isValid =>
      _payload!.isValid && _variableHeader!.messageIdentifier != 0;

  /// Write length
  int getWriteLength() {
    if (!isValid) {
      return 0;
    }
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    writeTo(stream);
    return stream.length;
  }

  /// Adds a new subscription topic with the default Qos level.
  MqttSubscribeMessage toTopic(String topic) {
    final subTopic = MqttSubscriptionTopic(topic);
    _payload!.addSubscription(subTopic);
    return this;
  }

  /// Adds a new subscription topic with the specified Qos level[MqttQos].
  MqttSubscribeMessage toTopicWithQos(String? topic, MqttQos? withQos) {
    final subTopic = MqttSubscriptionTopic(topic);
    final option = MqttSubscriptionOption();
    option.maximumQos = withQos;
    _payload!.addSubscription(subTopic, option);
    return this;
  }

  /// Adds a new subscription with the specified subscription option[MqttSubscriptionOption].
  MqttSubscribeMessage toTopicWithOption(
      String? topic, MqttSubscriptionOption option) {
    final subTopic = MqttSubscriptionTopic(topic);
    _payload!.addSubscription(subTopic, option);
    return this;
  }

  /// Adds a new subscription with the specified subscription
  MqttSubscribeMessage toSubscription(MqttSubscription subscription) {
    _payload!.addSubscription(subscription.topic, subscription.option);
    return this;
  }

  /// Adds a new subscription with the specified subscription list
  MqttSubscribeMessage toSubscriptionList(
      List<MqttSubscription> subscriptions) {
    for (final subscription in subscriptions) {
      _payload!.addSubscription(subscription.topic, subscription.option);
    }
    return this;
  }

  /// Subscription identifier
  MqttSubscribeMessage withSubscriptionIdentifier(int identifier) {
    _variableHeader!.subscriptionIdentifier = identifier;
    return this;
  }

  /// User property
  MqttSubscribeMessage withUserProperty(MqttUserProperty property) {
    _variableHeader!.userProperty = [property];
    return this;
  }

  /// User properties
  MqttSubscribeMessage withUserProperties(List<MqttUserProperty>? properties) {
    _variableHeader!.userProperty = properties;
    return this;
  }

  /// Set the message identifier
  set messageIdentifier(int identifier) =>
      _variableHeader!.messageIdentifier = identifier;

  /// Sets the duplicate flag for the message to indicate its a
  /// duplicate of a previous message type
  /// with the same message identifier.
  MqttSubscribeMessage isDuplicate() {
    header!.isDuplicate();
    return this;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.write(variableHeader);
    sb.write(payload);
    return sb.toString();
  }
}
