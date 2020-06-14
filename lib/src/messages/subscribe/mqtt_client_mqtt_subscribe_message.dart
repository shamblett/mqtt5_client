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
    header.qos = MqttQos.atLeastOnce;
    variableHeader = MqttSubscribeVariableHeader();
    payload = MqttSubscribePayload();
  }

  /// Initializes a new instance of the MqttSubscribeMessage class.
  MqttSubscribeMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    this.header.qos = MqttQos.atLeastOnce;
    readFrom(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  MqttSubscribeVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttSubscribePayload payload;

  String _lastTopic;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header.writeTo(variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    variableHeader = MqttSubscribeVariableHeader.fromByteBuffer(messageStream);
    payload = MqttSubscribePayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Adds a new subscription topic with the AtMostOnce Qos Level.
  /// If you want to change the Qos level follow this call with a
  /// call to AtTopic(MqttQos).
  MqttSubscribeMessage toTopic(String topic) {
    //lastTopic = topic;
    //payload.addSubscription(topic, MqttQos.atMostOnce);
    //return this;
  }

  /// Sets the Qos level of the last topic added to the subscription
  /// list via a call to ToTopic(string).
  MqttSubscribeMessage atQos(MqttQos qos) {
    //if (payload.subscriptions.containsKey(_lastTopic)) {
      //payload.subscriptions[_lastTopic] = qos;
    //}
    //return this;
  }

  /// Sets the message identifier on the subscribe message.
  MqttSubscribeMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the message up to request acknowledgement from the
  /// broker for each topic subscription.
  MqttSubscribeMessage expectAcknowledgement() {
    header.withQos(MqttQos.atLeastOnce);
    return this;
  }

  /// Sets the duplicate flag for the message to indicate its a
  /// duplicate of a previous message type
  /// with the same message identifier.
  MqttSubscribeMessage isDuplicate() {
    header.isDuplicate();
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
