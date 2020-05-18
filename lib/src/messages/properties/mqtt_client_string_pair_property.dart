/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// String pair property
class MqttStringPairProperty implements MqttIProperty {
  /// Construction
  MqttStringPairProperty([this.identifier]);

  /// Identifier
  @override
  MqttPropertyIdentifier identifier = MqttPropertyIdentifier.notSet;

  /// The value
  @override
  final value = MqttStringPair();

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    final buff = value.nameAsUtf8;
    buff.addAll(value.valueAsUtf8);
    stream.write(buff);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    value.name = stream.readMqttStringM();
    value.value = stream.readMqttStringM();
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() =>
      value.nameAsUtf8.length + value.valueAsUtf8.length + 1;

  /// Set the name
  set pairName(String val) => value.name = val;

  /// Set the value
  set pairValue(String val) => value.value = val;

  /// Get the name
  String get pairName => value.name;

  /// Get the value
  String get pairValue => value.value;

  @override
  String toString() {
    return 'Identifier : ${mqttPropertyIdentifier.asString(identifier)}, name : $pairName value : $pairValue';
  }
}