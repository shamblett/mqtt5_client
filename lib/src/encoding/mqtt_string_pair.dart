/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A UTF-8 String Pair consists of two UTF-8 Encoded Strings.
/// This data type is used to hold name-value pairs. The first string serves as the
/// name, and the second string contains the value.
class MqttStringPair {
  /// The name
  String name = '';

  /// The value
  String value = '';

  final _enc = MqttUtf8Encoding();

  /// Name as UTF8
  typed.Uint8Buffer get nameAsUtf8 => _enc.toUtf8(name);

  /// Value as UTF8
  typed.Uint8Buffer get valueAsUtf8 => _enc.toUtf8(value);
}
