/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of the variable header for an MQTT Publish message.
/// The Variable Header of the Publish message contains the following fields in the
/// order: Topic Name, Packet Identifier, and Properties.
class MqttPublishVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader(this.header);

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader.fromByteBuffer(
      this.header, MqttByteBuffer variableHeaderStream) {
    readFrom(variableHeaderStream);
  }

  /// Standard header
  MqttHeader header;

  /// Length
  @override
  int length = 0;

  /// Topic name
  String topicName = '';

  /// Message identifier
  int messageIdentifier = 0;

  /// Properties
  final _propertySet = MqttPropertyContainer();

  /// Encoder
  final MqttUtf8Encoding _enc = MqttUtf8Encoding();

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readTopicName(variableHeaderStream);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      readMessageIdentifier(variableHeaderStream);
    }
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeTopicName(variableHeaderStream);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      writeMessageIdentifier(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    headerLength += _enc.byteCount(topicName);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      headerLength += 2;
    }
    return headerLength;
  }

  /// Topic name
  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    length += _enc.byteCount(topicName);
  }

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Topic name
  void writeTopicName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, topicName.toString());
  }

  /// Message identifier
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('TopicName = {$topicName}');
    sb.writeln('MessageIdentifier = {$messageIdentifier}');
    return sb.toString();
  }
}
