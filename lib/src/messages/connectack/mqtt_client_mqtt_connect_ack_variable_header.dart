/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of the variable header for an MQTT ConnectAck message.
///
/// The Variable Header of the Connect Acknowledgement message contains the following fields
/// in the order: Connect Acknowledge Flags, Connect Reason Code, and Properties.
class MqttConnectAckVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {

  }

  @override
  int length = 0;

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {

  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {

  }

  /// Gets the length of the write data when WriteTo will be called.
  /// This method is overriden by the ConnectAckVariableHeader because the
  /// variable header of this message type, for some reason, contains an extra
  /// byte that is not present in the variable header spec, meaning we have to
  /// do some custom serialization and deserialization.
  @override
  int getWriteLength() => 2;

  @override
  String toString() {}

}
