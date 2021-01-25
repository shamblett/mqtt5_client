/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Variable byte integer property
class MqttVariableByteIntegerProperty implements MqttIProperty {
  /// Construction
  MqttVariableByteIntegerProperty([this.identifier]);

  /// Identifier
  @override
  MqttPropertyIdentifier? identifier = MqttPropertyIdentifier.notSet;

  /// Value
  @override
  int value = 0;

  final _enc = MqttVariableByteIntegerEncoding();

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    stream.write(_enc.fromInt(value));
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    final buffer = typed.Uint8Buffer();
    var end = false;
    while (!end) {
      var byte = stream.readByte();
      buffer.add(byte);
      if (byte < 128) {
        end = true;
      }
    }
    value = _enc.toInt(buffer);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => _enc.fromInt(value).length + 1;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
