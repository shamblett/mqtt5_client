// ignore_for_file: no-magic-number

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Utility class to assist with the build in of message topic payloads.
class MqttPayloadBuilder {
  typed.Uint8Buffer? _payload;

  /// Payload
  typed.Uint8Buffer? get payload => _payload;

  /// Length
  int get length => _payload!.length;

  /// Construction
  MqttPayloadBuilder() {
    _payload = typed.Uint8Buffer();
  }

  /// Add a buffer
  void addBuffer(typed.Uint8Buffer buffer) {
    _payload!.addAll(buffer);
  }

  /// Add byte, this will overflow on values > 2**8-1
  void addByte(int val) {
    _payload!.add(val);
  }

  /// Add a bool, true is 1, false is 0
  void addBool({required bool val}) {
    val ? addByte(1) : addByte(0);
  }

  /// Add a halfword, 16 bits, this will overflow on values > 2**16-1
  void addHalf(int val) {
    final tmp = Uint16List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
  }

  /// Add a word, 32 bits, this will overflow on values > 2**32-1
  void addWord(int val) {
    final tmp = Uint32List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
  }

  /// Add a long word, 64 bits or a Dart int
  void addInt(int val) {
    final tmp = Uint64List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
  }

  /// Add a standard Dart string
  void addString(String val) {
    addUTF16String(val);
  }

  /// Add a UTF16 string, note Dart natively encodes strings as UTF16
  void addUTF16String(String val) {
    for (final codeunit in val.codeUnits) {
      if (codeunit <= 255 && codeunit >= 0) {
        _payload!.add(codeunit);
      } else {
        addHalf(codeunit);
      }
    }
  }

  /// Add a UTF8 string
  void addUTF8String(String val) {
    const encoder = Utf8Encoder();
    _payload!.addAll(encoder.convert(val));
  }

  /// Add a will payload
  ///
  /// Will payloads are Binary Data as defined by the MQTT 5 specification
  void addWillPayload(String val) {
    _payload!.addAll(MqttUtf8Encoding().toUtf8(val));
  }

  /// Add a 32 bit double
  void addHalfDouble(double val) {
    final tmp = Float32List.fromList(<double>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
  }

  /// Add a 64 bit double
  void addDouble(double val) {
    final tmp = Float64List.fromList(<double>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
  }

  /// Clear the buffer
  void clear() => _payload!.clear();
}
