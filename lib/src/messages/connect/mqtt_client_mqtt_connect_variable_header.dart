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
    protocolName = MqttClientProtocol.name;
    protocolVersion = MqttClientProtocol.version;
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
  String protocolName = MqttClientProtocol.name;

  /// Protocol version
  int protocolVersion = MqttClientProtocol.version;

  /// Connect flags
  MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive = 0;

  /// Return code
  MqttConnectReturnCode returnCode = MqttConnectReturnCode.brokerUnavailable;

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

  /// Connect flags
  void writeConnectFlags(MqttByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  /// Protocol name
  void readProtocolName(MqttByteBuffer stream) {
    protocolName = MqttByteBuffer.readMqttString(stream);
    length += _enc.byteCount(protocolName);
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
