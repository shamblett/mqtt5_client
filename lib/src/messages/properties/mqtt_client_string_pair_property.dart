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
  MqttStringPairProperty(this.identifier);

  /// Identifier
  @override
  MqttPropertyIdentifier identifier = MqttPropertyIdentifier.notSet;

  /// The value
  final pair = MqttStringPair();

  /// Serialize to a byte buffer stream
  @override
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(mqttPropertyIdentifier.asInt(identifier));
    final buff = pair.nameAsUtf8;
    buff.addAll(pair.valueAsUtf8);
    stream.write(buff);
  }

  /// Deserialize from a byte buffer stream
  @override
  void readFrom(MqttByteBuffer stream) {
    identifier = mqttPropertyIdentifier.fromInt(stream.readByte());
    pair.name = stream.readMqttStringM();
    pair.value = stream.readMqttStringM();
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => pair.nameAsUtf8.length + pair.valueAsUtf8.length + 1;

  /// Set the name
  set name(String val) => pair.name = val;

  /// Set the value
  set value(String val) => pair.value = val;

  /// Get the name
  String get name => pair.name;

  /// Get the value
  String get value => pair.value;
}
