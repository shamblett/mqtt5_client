/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Message that indicates a connection acknowledgement.
///
/// The Connection Acknowledgement message is the message sent by the broker in response
/// to a Connect message received from the client.
class MqttConnectAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttConnectAckMessage class.
  /// Only called via the MqttMessage.Create operation during processing
  /// of an Mqtt message stream.
  MqttConnectAckMessage() {
    header = MqttHeader().asType(MqttMessageType.connectAck);
    variableHeader = MqttConnectAckVariableHeader();
  }

  /// Initializes a new instance of the MqttConnectAckMessage from a byte buffer
  MqttConnectAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message
  MqttConnectAckVariableHeader variableHeader;

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    variableHeader = MqttConnectAckVariableHeader.fromByteBuffer(messageStream);
  }

  /// Writes a message to the supplied stream. Not implemented for this message.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    throw UnimplementedError('MqttConnectAckMessage::writeTo - message is receive only');
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
