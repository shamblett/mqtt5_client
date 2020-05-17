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

  /// Read/Write length
  static const length = 5;

  /// Identifier
  @override
  MqttPropertyIdentifier identifier = MqttPropertyIdentifier.notSet;

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
    var buffer = stream.read(length - 1);
    value = _enc.toInt(buffer);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => length;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
