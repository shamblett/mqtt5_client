/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Sent by a broker to the client in response to a ping request message.
///
/// This message is used in keep alive processing.
class MqttPingResponseMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPingResponseMessage class.
  MqttPingResponseMessage() {
    header = MqttHeader().asType(MqttMessageType.pingResponse);
  }

  /// Initializes a new instance of the MqttPingResponseMessage class.
  MqttPingResponseMessage.fromHeader(MqttHeader header) {
    this.header = header;
  }

  /// Initializes a new instance of the MqttPingResponseMessage class.
  MqttPingResponseMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer stream) {
    this.header = header;
    readFrom(stream);
  }

  /// Writes the message to the supplied stream.
  /// Not implemented, message is receive only.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    throw UnimplementedError(
        'MqttPingRequestMessage::readFrom - not implemented, message is receive only');
  }

  /// Read from a message stream.
  @override
  void readFrom(MqttByteBuffer stream) {
    super.readFrom(stream);
    stream.shrink();
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    return sb.toString();
  }
}
