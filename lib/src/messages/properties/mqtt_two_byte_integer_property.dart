/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Two Byte Integer data values are 16-bit unsigned integers in big-endian order:
/// the high order byte precedes the lower order byte. This means that a
/// 16-bit word is presented on the network as Most Significant Byte (MSB),
/// followed by Least Significant Byte (LSB).
class MqttTwoByteIntegerProperty implements MqttIProperty {
  /// Construction
  MqttTwoByteIntegerProperty([this.identifier]);

  /// Read/Write length
  static const length = 3;

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
    stream.writeByte((value! >> 8) & 0xff);
    stream.writeByte(value! & 0xff);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    var buffer = stream.read(length - 1);
    value = buffer[0] << 8 | buffer[1];
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => length;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
