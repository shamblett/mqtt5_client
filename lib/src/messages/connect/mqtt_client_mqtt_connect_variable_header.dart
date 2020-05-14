/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of the variable header for an MQTT Connect message.
///
/// The Variable Header for the CONNECT Packet contains the following fields
/// in this order: Protocol Name, Protocol Level, Connect Flags,
/// Keep Alive, and Properties.
class MqttConnectVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectVariableHeader() {
    protocolName = Protocol.name;
    protocolVersion = Protocol.version;
    connectFlags = MqttConnectFlags();
  }

  /// Initializes a new instance of the MqttVariableHeader class,
  /// populating it with data from a stream.
  MqttConnectVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  @override
  int length;

  /// Protocol name
  String protocolName = '';

  /// Protocol version
  int protocolVersion = 0;

  /// Connect flags
  MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive = 0;

  /// Return code
  MqttConnectReturnCode returnCode = MqttConnectReturnCode.brokerUnavailable;

  /// Topic name
  String topicName = '';

  /// Message identifier
  int messageIdentifier = 0;

  /// Encoder
  final MqttUtf8Encoding _enc = MqttUtf8Encoding();

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readProtocolName(variableHeaderStream);
    readProtocolVersion(variableHeaderStream);
    readConnectFlags(variableHeaderStream);
    readKeepAlive(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeProtocolName(variableHeaderStream);
    writeProtocolVersion(variableHeaderStream);
    writeConnectFlags(variableHeaderStream);
    writeKeepAlive(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    final enc = MqttUtf8Encoding();
    headerLength += enc.byteCount(protocolName);
    headerLength += 1; // protocolVersion
    headerLength += MqttConnectFlags.getWriteLength();
    headerLength += 2; // keepAlive
    return headerLength;
  }

  /// Protocol name
  void writeProtocolName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, protocolName);
  }

  /// Protocol version
  void writeProtocolVersion(MqttByteBuffer stream) {
    stream.writeByte(protocolVersion);
  }

  /// Keep alive
  void writeKeepAlive(MqttByteBuffer stream) {
    stream.writeShort(keepAlive);
  }

  /// Return code
  void writeReturnCode(MqttByteBuffer stream) {
    stream.writeByte(returnCode.index);
  }

  /// Topic name
  void writeTopicName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, topicName.toString());
  }

  /// Message identifier
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  /// Connect flags
  void writeConnectFlags(MqttByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  /// Read functions

  /// Protocol name
  void readProtocolName(MqttByteBuffer stream) {
    protocolName = MqttByteBuffer.readMqttString(stream);
    length += protocolName.length + 2; // 2 for length short at front of string
  }

  /// Protocol version
  void readProtocolVersion(MqttByteBuffer stream) {
    protocolVersion = stream.readByte();
    length++;
  }

  /// Keep alive
  void readKeepAlive(MqttByteBuffer stream) {
    keepAlive = stream.readShort();
    length += 2;
  }

  /// Return code
  void readReturnCode(MqttByteBuffer stream) {
    returnCode = MqttConnectReturnCode.values[stream.readByte()];
    length++;
  }

  /// Topic name
  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    // If the protocol si V311 allow extended UTF8 characters
    if (Protocol.version == MqttClientConstants.mqttProtocolVersion) {
      length += _enc.byteCount(topicName);
    } else {
      length = topicName.length + 2; // 2 for length short at front of string.
    }
  }

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Connect flags
  void readConnectFlags(MqttByteBuffer stream) {
    connectFlags = MqttConnectFlags.fromByteBuffer(stream);
    length += 1;
  }

  @override
  String toString() => 'Connect Variable Header: ProtocolName=$protocolName, '
      'ProtocolVersion=$protocolVersion, '
      'ConnectFlags=${connectFlags.toString()}, '
      'KeepAlive=$keepAlive';
}
