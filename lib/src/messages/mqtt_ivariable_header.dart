/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Variable header base class
///
/// Some types of MQTT Control Packet contain a Variable Header component. It resides
/// between the Fixed Header and the Payload. The content of the Variable Header
/// varies depending on the message type. The Packet Identifier field of
/// Variable Header is common in several message types.
abstract class MqttIVariableHeader {
  /// The length of the variable header in bytes
  int get length;

  /// Serialize to a byte buffer stream
  void writeTo(MqttByteBuffer stream);

  /// Deserialize from a byte buffer stream
  void readFrom(MqttByteBuffer stream);

  /// Gets the length of the write data when WriteTo will be called.
  /// A subclass that overrides writeTo must also overwrite this method.
  int getWriteLength();
}
