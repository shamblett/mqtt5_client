/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Connect acknowledgement message [MqttConnectAckMessage] flags.
class MqttConnectAckFlags {
  /// Construction
  MqttConnectAckFlags();

  /// Session present
  /// The Session Present flag informs the client whether the broker is using Session
  /// State from a previous connection for this ClientID. This allows the client
  /// and broker to have a consistent view of the Session State.
  bool sessionPresent = false;

  /// Read from a byte stream
  void readFrom(MqttByteBuffer variableHeaderStream) {
    final byte = variableHeaderStream.readByte();
    sessionPresent = byte & 0x01 == 1;
  }

  /// Length
  int get length => 1;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Session Present = $sessionPresent');
    return sb.toString();
  }
}
