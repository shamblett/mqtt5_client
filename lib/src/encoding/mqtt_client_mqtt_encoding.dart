/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Encoding implementation that can encode and decode strings
/// in the MQTT string format.
///
/// Text fields within the MQTT Control Packets are encoded as UTF-8 strings.
/// UTF-8 [RFC3629] is an efficient encoding of Unicode [Unicode] characters that
/// optimizes the encoding of ASCII characters in support of text-based communications.
///
/// Each of these strings is prefixed with a two byte integer length field that gives the number
/// of bytes in a UTF-8 encoded string itself.
/// Consequently, the maximum size of a UTF-8 encoded string is 65,535 bytes.
///
class MqttEncoding extends Utf8Codec {
  /// Encodes all the characters in the specified string
  /// into a sequence of bytes.
  typed.Uint8Buffer getBytes(String s) {
    final stringConverted = encoder.convert(s);
    _validateString(stringConverted);
    final stringBytes = typed.Uint8Buffer();
    stringBytes.add(stringConverted.length >> 8);
    stringBytes.add(stringConverted.length & 0xFF);
    stringBytes.addAll(stringConverted);
    return stringBytes;
  }

  /// Decodes the bytes in the specified byte array into a string.
  String getString(typed.Uint8Buffer bytes) => decoder.convert(bytes.toList());

  ///  Calculates the number of characters produced by decoding all the bytes
  ///  in the specified byte array.
  int getCharCount(typed.Uint8Buffer bytes) {
    if (bytes.length < 2) {
      throw Exception(
          'mqtt_client::MQTTEncoding: Length byte array must comprise 2 bytes');
    }
    return (bytes[0] << 8) + bytes[1];
  }

  /// Calculates the number of bytes produced by encoding the
  /// characters in the specified.
  int getByteCount(String chars) => getBytes(chars).length;

  /// Validates the string to ensure it doesn't contain any characters
  /// invalid within the Mqtt string format.
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
  ///         U+0001..U+001F control characters
  ///         U+007F..U+009F control characters
  ///         Code points defined in the Unicode specification [Unicode] to be non-characters (for example U+0FFFF)
  static void _validateString(Uint8List s) {
    // TODO
  }
}
