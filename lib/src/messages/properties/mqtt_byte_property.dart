/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// Byte property
class MqttByteProperty implements MqttIProperty {
  /// Read/Write length
  static const length = 2;

  /// Identifier
  @override
  MqttPropertyIdentifier? identifier = MqttPropertyIdentifier.notSet;

  /// Value
  @override
  int value = 0;

  /// Construction
  MqttByteProperty([this.identifier]);

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    stream.writeByte(value);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    identifier ??= MqttPropertyIdentifier.notSet;
    value = stream.readByte();
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => length;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, value : $value';
  }
}
