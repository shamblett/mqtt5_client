/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The Variable Byte Integer is encoded using an encoding scheme which uses a single
/// byte for values up to 127. Larger values are handled as follows. The least significant
/// seven bits of each byte encode the data, and the most significant bit is used to
/// indicate whether there are bytes following in the representation.
/// Thus, each byte encodes 128 values and a "continuation bit".
///
/// The maximum number of bytes in the Variable Byte Integer field is four.
/// The encoded value MUST use the minimum number of bytes necessary to
/// represent the value [MQTT-1.5.5-1].
class MqttByteIntegerEncoding {
  /// Byte integer to integer
  int toInt(typed.Uint8Buffer byteInteger) {
    // Must be a maximum length of 4
    if (byteInteger.isEmpty || byteInteger.length > 4) {
      throw ArgumentError(
          'MqttByteIntegerEncoding::toInt byte integer has an invalid length ${byteInteger?.length}');
    }
    var multiplier = 1;
    var value = 0;
    var index = 0;
    var encodedByte = 0;

    do {
      encodedByte = byteInteger[index];
      value += (encodedByte & 127) * multiplier;
      if (multiplier > 128 * 128 * 128) {
        throw ArgumentError(
            'MqttByteIntegerEncoding::toInt Malformed Variable Byte Integer');
      }
      multiplier *= 128;
      index++;
    } while ((encodedByte & 128) != 0);
    return value;
  }

  /// Integer to byte integer
  typed.Uint8Buffer fromInt(int value) {
    var x = value;
    var encodedByte = 0;
    var result = typed.Uint8Buffer();

    do {
      encodedByte = x % 128;
      x = x ~/ 128;
      // if there is more data to encode, set the top bit of this byte
      if (x > 0) {
        encodedByte = encodedByte | 128;
      }

      result.add(encodedByte);
    } while (x > 0);

    // Must be a maximum length of 4
    if (result.isEmpty || result.length > 4) {
      throw ArgumentError(
          'MqttByteIntegerEncoding::fromInt byte integer has an invalid length ${result.length}, value is $value');
    }
    return result;
  }
}
