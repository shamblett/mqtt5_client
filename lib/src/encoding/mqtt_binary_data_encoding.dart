/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Binary Data is represented by a Two Byte Integer length which indicates the number of data bytes,
/// followed by that number of bytes. Thus, the length of Binary Data is limited
/// to the range of 0 to 65,535 Bytes.
class MqttBinaryDataEncoding {
  static const byteLength = 8;
  static const byteMask = 0xFF;

  /// To binary data
  typed.Uint8Buffer toBinaryData(typed.Uint8Buffer? data) {
    if (data == null || data.isEmpty) {
      throw Exception(
        'MqttBinaryDataEncoding::toBinaryData  -  data is null or empty',
      );
    }
    if (data.length > MqttConstants.maxBinaryDataLength) {
      throw Exception(
        'MqttBinaryDataEncoding::toBinaryData  -  data length is invalid, length is ${data.length}',
      );
    }
    final dataBytes = typed.Uint8Buffer();
    dataBytes.add(data.length >> byteLength);
    dataBytes.add(data.length & byteMask);
    dataBytes.addAll(data);
    return dataBytes;
  }

  /// From binary data
  typed.Uint8Buffer fromBinaryData(typed.Uint8Buffer data) {
    var len = length(data);
    return typed.Uint8Buffer()..addAll(
      data.getRange(
        MqttConstants.minBinaryDataLength,
        MqttConstants.minBinaryDataLength + len,
      ),
    );
  }

  /// Length of a binary data sequence
  int length(typed.Uint8Buffer data) {
    if (data.length < MqttConstants.minBinaryDataLength) {
      throw Exception(
        'MqttBinaryDataEncoding::length length byte array must comprise 2 bytes',
      );
    }
    return (data.first << byteLength) + data[1];
  }
}
