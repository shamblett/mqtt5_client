/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// UTF8 String property
class MqttUtf8StringProperty implements MqttIProperty {
  /// Construction
  MqttUtf8StringProperty([this.identifier]);

  /// Identifier
  @override
  MqttPropertyIdentifier? identifier = MqttPropertyIdentifier.notSet;

  /// Value
  @override
  String? value;

  final _enc = MqttUtf8Encoding();

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    stream.write(_enc.toUtf8(value!));
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    final lenBuffer = stream.read(2);
    final length = _enc.length(lenBuffer);
    final buffer = stream.read(length);
    final stringBuffer = typed.Uint8Buffer();
    stringBuffer.addAll(lenBuffer);
    stringBuffer.addAll(buffer);
    value = _enc.fromUtf8(stringBuffer);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => _enc.byteCount(value!) + 1;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
