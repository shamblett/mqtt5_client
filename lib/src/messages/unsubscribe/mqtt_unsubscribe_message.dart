/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An unsubscribe message is sent by the client to the broker,
/// to unsubscribe from topics.
class MqttUnsubscribeMessage extends MqttMessage {
  /// Initializes a new instance of the MqttUnsubscribeMessage class.
  MqttUnsubscribeMessage() {
    header = MqttHeader().asType(MqttMessageType.unsubscribe);
    // Qos of at least once has to be specified for this message.
    header!.qos = MqttQos.atLeastOnce;
  }

  final _variableHeader = MqttUnsubscribeVariableHeader();

  /// Gets the variable header.
  MqttUnsubscribeVariableHeader get variableHeader => _variableHeader;

  final _payload = MqttUnsubscribePayload();

  /// Gets the payload.
  MqttUnsubscribePayload get payload => _payload;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  /// Not implemented, message is send only.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    throw UnimplementedError(
        'MqttUnsubscribeMessage::readFrom - not implemented, message is send only');
  }

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

  /// Adds a raw topic to the list of topics to unsubscribe from.
  MqttUnsubscribeMessage fromStringTopic(String topic) {
    payload.addStringSubscription(topic);
    return this;
  }

  /// Adds a topic to the list of topics to unsubscribe from.
  MqttUnsubscribeMessage fromTopic(MqttSubscriptionTopic topic) {
    payload.addTopicSubscription(topic);
    return this;
  }

  /// Adds a new unsubscription with the specified subscription list
  MqttUnsubscribeMessage fromSubscriptionList(
      List<MqttSubscription> subscriptions) {
    for (final subscription in subscriptions) {
      _payload.addTopicSubscription(subscription.topic);
    }
    return this;
  }

  /// Sets the message identifier on the subscribe message.
  MqttUnsubscribeMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// User property
  MqttUnsubscribeMessage withUserProperty(MqttUserProperty property) {
    _variableHeader.userProperty = [property];
    return this;
  }

  /// User properties
  MqttUnsubscribeMessage withUserProperties(List<MqttUserProperty> properties) {
    _variableHeader.userProperty = properties;
    return this;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
