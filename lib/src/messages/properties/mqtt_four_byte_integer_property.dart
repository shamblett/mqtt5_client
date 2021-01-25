/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Four Byte Integer data values are 32-bit unsigned integers in big-endian order:
/// the high order byte precedes the successively lower order bytes.
/// This means that a 32-bit word is presented on the network as
/// Most Significant Byte (MSB), followed by the next most Significant Byte (MSB),
/// followed by the next most Significant Byte (MSB), followed by Least Significant
/// Byte (LSB).
class MqttFourByteIntegerProperty implements MqttIProperty {
  /// Construction
  MqttFourByteIntegerProperty([this.identifier]);

  /// Read/Write length
  static const length = 5;

  /// Identifier
  @override
  MqttPropertyIdentifier? identifier = MqttPropertyIdentifier.notSet;

  /// Value
  @override
  int? value = 0;

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    stream.writeByte((value! >> 24) & 0xff);
    stream.writeByte((value! >> 16) & 0xff);
    stream.writeByte((value! >> 8) & 0xff);
    stream.writeByte(value! & 0xff);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    var buffer = stream.read(length - 1);
    value = buffer[0] << 24 | buffer[1] << 16 | buffer[2] << 8 | buffer[3];
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => length;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
