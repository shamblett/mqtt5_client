/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A Publish message is sent to a broker to transport an application message.
///
/// Various fields are used in the construction of this message, for more details on
/// the meaning of these fields please refer to the classes in which they are defined,
/// specifically [MqttPublishVariableHeader] and [MqttPublishPayload].

class MqttPublishMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage() {
    header = MqttHeader().asType(MqttMessageType.publish);
    _variableHeader = MqttPublishVariableHeader(header);
    payload = MqttPublishPayload();
  }

  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  MqttPublishVariableHeader? _variableHeader;

  /// The variable header contents. Contains extended metadata about the message.
  MqttPublishVariableHeader? get variableHeader => _variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  late MqttPublishPayload payload;

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    _variableHeader =
        MqttPublishVariableHeader.fromByteBuffer(header, messageStream);
    payload = MqttPublishPayload.fromByteBuffer(
        header, variableHeader, messageStream);
    messageStream.shrink();
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    final variableHeaderLength = variableHeader!.getWriteLength();
    final payloadLength = payload.getWriteLength();
    header!.writeTo(variableHeaderLength + payloadLength, messageStream);
    variableHeader!.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Sets the topic to publish data to.
  MqttPublishMessage toTopic(String topicName) {
    variableHeader!.topicName = topicName;
    return this;
  }

  /// Sets the message identifier of the message.
  MqttPublishMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader!.messageIdentifier = messageIdentifier;
    return this;
  }

  ///  Sets the Qos of the published message.
  MqttPublishMessage withQos(MqttQos qos) {
    header!.withQos(qos);
    return this;
  }

  /// Payload Format Indicator
  MqttPublishMessage withPayloadFormatIndicator(bool indicator) {
    _variableHeader!.payloadFormatIndicator = indicator;
    return this;
  }

  /// Message Expiry Interval
  MqttPublishMessage withMessageExpiryInterval(int interval) {
    _variableHeader!.messageExpiryInterval = interval;
    return this;
  }

  /// Topic Alias
  MqttPublishMessage withTopicAlias(int alias) {
    _variableHeader!.topicAlias = alias;
    return this;
  }

  /// Response Topic
  MqttPublishMessage withResponseTopic(String topic) {
    _variableHeader!.responseTopic = topic;
    return this;
  }

  /// Correlation Data
  MqttPublishMessage withResponseCorrelationdata(typed.Uint8Buffer data) {
    _variableHeader!.correlationData = data;
    return this;
  }

  /// Sets a list of user properties
  MqttPublishMessage withUserProperties(List<MqttUserProperty>? properties) {
    _variableHeader!.userProperty = properties;
    return this;
  }

  /// Add a specific user property
  void addUserProperty(MqttUserProperty property) {
    _variableHeader!.userProperty = [property];
  }

  /// Add a user property from the supplied name/value pair
  void addUserPropertyPair(String name, String value) {
    final property = MqttUserProperty();
    property.pairName = name;
    property.pairValue = value;
    addUserProperty(property);
  }

  /// Subscription Identifier
  MqttPublishMessage withSubscriptionIdentifier(int identifier) {
    _variableHeader!.subscriptionIdentifier = identifier;
    return this;
  }

  /// Content Type
  MqttPublishMessage withContentType(String type) {
    _variableHeader!.contentType = type;
    return this;
  }

  /// Removes the current published data, i.e. clears the payload
  MqttPublishMessage clearPublishData() {
    payload.message!.clear();
    return this;
  }

  /// Appends data to publish to the end of the current message payload.
  MqttPublishMessage publishData(typed.Uint8Buffer data) {
    payload.message!.addAll(data);
    return this;
  }

  /// Set the retain flag on the message
  void setRetain({bool? state}) {
    if ((state != null) && state) {
      header!.shouldBeRetained();
    }
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
