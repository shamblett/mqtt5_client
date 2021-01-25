/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Binary data property
class MqttBinaryDataProperty implements MqttIProperty {
  /// Construction
  MqttBinaryDataProperty([this.identifier]);

  /// Identifier
  @override
  MqttPropertyIdentifier? identifier = MqttPropertyIdentifier.notSet;

  /// Value
  @override
  final dynamic value = typed.Uint8Buffer();

  final _enc = MqttBinaryDataEncoding();

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    stream.write(_enc.toBinaryData(value));
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    final lenBuffer = stream.read(2);
    final length = _enc.length(lenBuffer);
    value.clear();
    value.addAll(stream.read(length));
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => _enc.toBinaryData(value).length + 1;

  /// Add a byte to the buffer
  void addByte(int byte) {
    value.add(byte);
  }

  /// Add a list of bytes to the buffer
  void addBytes(typed.Uint8Buffer? bytes) {
    value.addAll(bytes);
  }

  @override
  String toString() {
    return 'Identifier $identifier, value $value';
  }
}
