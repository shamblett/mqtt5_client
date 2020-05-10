/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Represents the payload (Body) of an MQTT Message.
abstract class MqttPayload {
  /// Initializes a new instance of the MqttPayload class.
  MqttPayload();

  /// Initializes a new instance of the MqttPayload class.
  MqttPayload.fromMqttByteBuffer(MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  /// Writes the payload to the supplied stream.
  /// A basic message has no Variable Header.
  void writeTo(MqttByteBuffer payloadStream);

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream);

  /// Gets the length of the payload in bytes when written to a stream.
  int getWriteLength();
}
