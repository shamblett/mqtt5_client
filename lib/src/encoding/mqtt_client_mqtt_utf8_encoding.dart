/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Encoding implementation that can encode and decode strings
/// in the MQTT UTF8 string format.
///
/// Text fields within the MQTT Control Packets are encoded as UTF-8 strings.
/// UTF-8 [RFC3629] is an efficient encoding of Unicode [Unicode] characters that
/// optimizes the encoding of ASCII characters in support of text-based communications.
///
/// Each of these strings is prefixed with a two byte integer length field that gives the number
/// of bytes in a UTF-8 encoded string itself.
/// Consequently, the maximum size of a UTF-8 encoded string is 65,535 bytes.
///
class MqttUtf8Encoding extends Utf8Codec {
  /// Encodes all the characters in the specified string
  /// into a sequence of bytes.
  typed.Uint8Buffer toUtf8(String s) {
    _validateString(s);
    final stringConverted = encoder.convert(s);
    if (stringConverted.length > 65535) {
      throw Exception(
          'MqttUtf8Encoding::toUtf8 -  UTF8 string length is invalid, length is ${stringConverted.length}');
    }
    final stringBytes = typed.Uint8Buffer();
    stringBytes.add(stringConverted.length >> 8);
    stringBytes.add(stringConverted.length & 0xFF);
    stringBytes.addAll(stringConverted);
    return stringBytes;
  }

  /// Decodes the bytes in the specified MQTT UTF8 encoded byte array into a string.
  String fromUtf8(typed.Uint8Buffer bytes) {
    var len = length(bytes);
    var utf8Bytes = bytes.toList().getRange(2, 2 + len);
    var decoded = decoder.convert(utf8Bytes.toList());
    _validateString(decoded);
    return decoded;
  }

  ///  Gets the length of a UTF8 encoded string from the length bytes
  int length(typed.Uint8Buffer bytes) {
    if (bytes.length < 2) {
      throw Exception(
          'MqttUtf8Encoding:: Length byte array must comprise 2 bytes');
    }
    return (bytes[0] << 8) + bytes[1];
  }

  /// Gets the total length of a UTF8 encoded string including the length bytes
  int byteCount(String chars) => toUtf8(chars).length;

  /// Validates the UTF8 string to ensure it doesn't contain any characters
  /// invalid within the MQTT string format.
  ///
  /// The character data in a UTF-8 Encoded String MUST be well-formed UTF-8
  /// as defined by the Unicode specification [Unicode]
  /// and restated in RFC 3629 [RFC3629]. In particular, the character
  /// data MUST NOT include encodings of code points between U+D800 and U+DFFF [MQTT-1.5.4-1].
  /// If the Client or Server receives an MQTT Control Packet containing ill-formed
  /// UTF-8 it is a Malformed Packet. Refer to section 4.13 for information about handling errors.
  ///
  /// A UTF-8 Encoded String MUST NOT include an encoding of the null character U+0000. [MQTT-1.5.4-2].
  /// If a receiver (Server or Client) receives an MQTT Control Packet containing U+0000 it
  /// is a Malformed Packet.
  ///
  /// The data SHOULD NOT include encodings of the Unicode [Unicode] code points listed below.
  /// If a receiver (Server or Client) receives an MQTT Control Packet containing any of them
  /// it MAY treat it as a Malformed Packet. These are the Disallowed Unicode code points.
  ///
  ///         U+0000..U+001F control characters
  ///         U+007F..U+009F control characters
  void _validateString(String s) {
    if (s.runes.any(
        (e) => (e >= 0x0000 && e <= 0x001f) || (e >= 0x007f && e <= 0x009f))) {
      throw Exception(
          'MqttUtf8Encoding:: UTF8 string is invalid, contains control characters');
    }
  }
}
