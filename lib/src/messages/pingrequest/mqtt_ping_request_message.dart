/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The ping request message is sent from the client to the broker. It can be used to:
///
/// Indicate to the broker that the client is alive in the absence of any other MQTT
/// messages being sent by the client.
///
/// Request that the broker responds to confirm that it is alive.
///
/// Exercise the network to indicate that the network connection is active.
///
/// This message is used in keep alive processing.
class MqttPingRequestMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPingRequestMessage class.
  MqttPingRequestMessage() {
    header = MqttHeader().asType(MqttMessageType.pingRequest);
  }

  /// Initializes a new instance of the MqttPingRequestMessage class.
  MqttPingRequestMessage.fromHeader(MqttHeader header) {
    this.header = header;
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    messageStream.writeByte(header!.messageType!.index << 4);
    messageStream.writeByte(0);
  }

  /// Read from a message stream.
  /// Not implemented, message is send only.
  @override
  void readFrom(MqttByteBuffer stream) {
    throw UnimplementedError(
        'MqttPingRequestMessage::readFrom - not implemented, message is send only');
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    return sb.toString();
  }
}
