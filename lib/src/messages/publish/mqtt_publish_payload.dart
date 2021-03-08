/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Class that contains details related to an MQTT Publish message payload
class MqttPublishPayload implements MqttIPayload {
  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload() {
    message = typed.Uint8Buffer();
  }

  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload.fromByteBuffer(
      this.header, this.variableHeader, MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  /// Receive length
  int length = 0;

  /// Message header
  MqttHeader? header;

  /// Variable header
  MqttPublishVariableHeader? variableHeader;

  /// The message that forms the payload of the publish message.
  typed.Uint8Buffer? message;

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    final messageBytes = header!.messageSize - variableHeader!.length;
    message = payloadStream.read(messageBytes);
    length += messageBytes;
  }

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.write(message);
  }

  /// Gets the length of the payload in bytes when written to a stream.
  @override
  int getWriteLength() => message!.length;

  @override
  String toString() =>
      'Payload: {${message!.length} bytes={${MqttUtilities.bytesToString(message!)}';
}
