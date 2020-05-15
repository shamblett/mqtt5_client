/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Byte property
class MqttFourByteIntegerProperty implements MqttIProperty {
  /// Construction
  MqttFourByteIntegerProperty(this.identifier);

  /// Read/Write length
  static const length = 5;

  /// Identifier
  @override
  MqttPropertyIdentifier identifier = MqttPropertyIdentifier.notSet;

  /// Value
  int value = 0;

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    var bytes = typed.Uint32Buffer()
      ..add(value)
      ..toList();
    var buffer = typed.Uint8Buffer();
    buffer.addAll(bytes.buffer.asUint8List());
    stream.writeByte(buffer[3]);
    stream.writeByte(buffer[2]);
    stream.writeByte(buffer[1]);
    stream.writeByte(buffer[0]);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    var buffer = stream.read(length - 1);
    var bytes = typed.Uint8Buffer();
    bytes.addAll(buffer.reversed);
    value = Uint32List.view(bytes.buffer)[0];
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => length;
}
