/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// The Variable Byte Integer is encoded using an encoding scheme which uses a single
/// byte for values up to 127. Larger values are handled as follows. The least significant
/// seven bits of each byte encode the data, and the most significant bit is used to
/// indicate whether there are bytes following in the representation.
/// Thus, each byte encodes 128 values and a "continuation bit".
///
/// The maximum number of bytes in the Variable Byte Integer field is four.
/// The encoded value MUST use the minimum number of bytes necessary to
/// represent the value [MQTT-1.5.5-1].
class MqttVariableByteIntegerEncoding {
  static const maxConvertibleValue = 268435455;
  static const maxLength = 4;
  static const singleValue = 127;
  static const multiValue = 128;

  /// Byte integer to integer
  int toInt(typed.Uint8Buffer? byteInteger) {
    if (byteInteger == null || byteInteger.isEmpty) {
      throw ArgumentError(
        'MqttByteIntegerEncoding::toInt byte integer is null or empty',
      );
    }
    var multiplier = 1;
    var value = 0;
    var index = 0;
    var encodedByte = 0;
    try {
      do {
        // Must be a maximum length of 4
        if (index > maxLength) {
          break;
        }
        encodedByte = byteInteger[index];
        value += (encodedByte & singleValue) * multiplier;
        if (multiplier > multiValue * multiValue * multiValue) {
          throw ArgumentError(
            'MqttByteIntegerEncoding::toInt Malformed Variable Byte Integer',
          );
        }
        multiplier *= multiValue;
        index++;
      } while ((encodedByte & multiValue) != 0);
    } on Error catch (_, stack) {
      Error.throwWithStackTrace(
        ArgumentError(
          'MqttByteIntegerEncoding::toInt invalid byte sequence $byteInteger',
        ),
        stack,
      );
    }
    if (index > maxLength) {
      throw FormatException(
        'MqttByteIntegerEncoding::toInt - variable byte integer is incorrectly formatted',
      );
    }
    return value;
  }

  /// Integer to byte integer
  /// The convertible value range is 0 .. 268,435,455 (0xFF, 0xFF, 0xFF, 0x7F)
  typed.Uint8Buffer fromInt(int value) {
    if (value > maxConvertibleValue || value < 0) {
      throw ArgumentError(
        'MqttByteIntegerEncoding::fromInt supplied value is not convertible $value',
      );
    }
    var x = value;
    var encodedByte = 0;
    var result = typed.Uint8Buffer();
    var count = 0;

    do {
      // We can't encode more than 4 bytes
      if (count > maxLength) {
        break;
      }
      encodedByte = x % multiValue;
      x = x ~/ multiValue;
      // if there is more data to encode, set the top bit of this byte
      if (x > 0) {
        encodedByte = encodedByte | multiValue;
      }

      result.add(encodedByte);
      count++;
    } while (x > 0);

    // Must be a maximum length of 4
    if (result.isEmpty || count > maxLength) {
      throw ArgumentError(
        'MqttByteIntegerEncoding::fromInt byte integer has an invalid length ${result.length}, value is $value',
      );
    }
    return result;
  }

  /// The length in bytes of the supplied value
  int length(int value) => fromInt(value).length;
}
