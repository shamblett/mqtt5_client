/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Base class for MQTT message properties
///
/// A Property consists of an Identifier which defines its
/// usage and data type, followed by a value.
abstract class MqttIProperty {
  /// Identifier
  MqttPropertyIdentifier? identifier;

  /// The value
  dynamic get value;

  /// Serialize to a byte buffer stream
  void writeTo(MqttByteBuffer stream);

  /// Deserialize from a byte buffer stream
  void readFrom(MqttByteBuffer stream);

  /// Gets the length of the write data when WriteTo will be called.
  /// A subclass that overrides writeTo must also overwrite this method.
  int? getWriteLength();
}
