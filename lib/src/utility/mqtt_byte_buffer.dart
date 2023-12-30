/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Utility class to allow stream like access to a sized byte buffer.
/// This class is in effect a cut-down implementation of the C# NET
/// System.IO class with Mqtt client specific extensions.
class MqttByteBuffer {
  /// The byte buffer
  MqttByteBuffer(this.buffer);

  /// From a list
  MqttByteBuffer.fromList(List<int> data) {
    buffer = typed.Uint8Buffer();
    buffer!.addAll(data);
  }

  /// The current position within the buffer.
  int _position = 0;

  /// The underlying byte buffer
  typed.Uint8Buffer? buffer;

  /// Position
  int get position => _position;

  /// Length
  int get length => buffer!.length;

  /// Available bytes
  int get availableBytes => length - _position;

  /// Resets the position to 0
  void reset() {
    _position = 0;
  }

  /// Skip bytes
  set skipBytes(int bytes) => _position += bytes;

  /// Add a list
  void addAll(List<int> data) {
    buffer!.addAll(data);
  }

  /// Shrink the buffer
  void shrink() {
    buffer!.removeRange(0, _position);
    _position = 0;
  }

  /// Message available
  bool isMessageAvailable() {
    if (availableBytes == 0) {
      return false;
    }

    // If we do not have 2 bytes we do not have a complete header, so no
    // message is available.
    if (length < 2) {
      return false;
    }

    // read the message size by peeking in to the header and return true only
    // if the whole message is available.

    // If the first byte of the header is 0 then skip past it.
    if (peekByte() == 0) {
      MqttLogger.log(
          'MqttByteBuffer:isMessageAvailable - first header byte is zero, skipping');
      _position++;
      shrink();
    }

    // Assume we now have a valid header
    MqttLogger.log(
        'MqttByteBuffer:isMessageAvailable - assumed valid header, value is ${peekByte()}');
    // Save the position
    var position = _position;
    var header = MqttHeader.fromByteBuffer(this);
    // Restore the position
    _position = position;
    if (availableBytes < header.messageSize) {
      MqttLogger.log(
          'MqttByteBuffer:isMessageAvailable - Available bytes($availableBytes) is less than the message size'
          ' ${header.messageSize}');

      return false;
    }

    return true;
  }

  /// Reads a byte from the buffer and advances the position
  /// within the buffer by one byte, or returns -1 if at the end of the buffer.
  int readByte() {
    final tmp = buffer![_position];
    if (_position <= (length - 1)) {
      _position++;
    } else {
      return -1;
    }
    return tmp;
  }

  /// Peeks a byte from the buffer
  int peekByte() => buffer![_position];

  /// Read a short int(16 bits)
  int readShort() {
    final high = readByte();
    final low = readByte();
    return (high << 8) + low;
  }

  /// Reads a sequence of bytes from the current
  /// buffer and advances the position within the buffer
  /// by the number of bytes read.
  typed.Uint8Buffer read(int count) {
    if ((length < count) || (_position + count) > length) {
      throw Exception('MqttByteBuffer::read: The buffer did not have '
          'enough bytes for the read operation '
          'length $length, count $count, position $_position, buffer $buffer');
    }
    final tmp = typed.Uint8Buffer();
    tmp.addAll(buffer!.getRange(_position, _position + count));
    _position += count;
    final tmp2 = typed.Uint8Buffer();
    tmp2.addAll(tmp);
    return tmp2;
  }

  /// Writes a byte to the current position in the buffer
  /// and advances the position within the buffer by one byte.
  void writeByte(int? byte) {
    if (buffer!.length == _position) {
      buffer!.add(byte!);
    } else {
      buffer![_position] = byte!;
    }
    _position++;
  }

  /// Write a short(16 bit)
  void writeShort(int short) {
    writeByte(short >> 8);
    writeByte(short & 0xFF);
  }

  /// Writes a sequence of bytes to the current
  /// buffer and advances the position within the buffer by the number of
  /// bytes written.
  void write(typed.Uint8Buffer? buffer) {
    if (this.buffer == null) {
      this.buffer = buffer;
    } else {
      this.buffer!.addAll(buffer!);
    }
    _position = length;
  }

  /// Seek. Sets the position in the buffer. If overflow occurs
  /// the position is set to the end of the buffer.
  void seek(int seek) {
    if ((seek <= length) && (seek >= 0)) {
      _position = seek;
    } else {
      _position = length;
    }
  }

  /// Writes an MQTT string member
  void writeMqttStringM(String? stringToWrite) {
    writeMqttString(this, stringToWrite);
  }

  /// Writes an MQTT string.
  /// stringStream - The stream containing the string to write.
  /// stringToWrite - The string to write.
  static void writeMqttString(
      MqttByteBuffer stringStream, String? stringToWrite) {
    if (stringToWrite != null) {
      final enc = MqttUtf8Encoding();
      final stringBytes = enc.toUtf8(stringToWrite);
      stringStream.write(stringBytes);
    }
  }

  /// Reads an MQTT string from the underlying stream member
  String readMqttStringM() => MqttByteBuffer.readMqttString(this);

  /// Reads an MQTT string from the underlying stream.
  static String readMqttString(MqttByteBuffer buffer) {
    final enc = MqttUtf8Encoding();
    final stringBuff = buffer.read(2);
    final length = enc.length(stringBuff);
    stringBuff.addAll(buffer.read(length));
    return enc.fromUtf8(stringBuff);
  }

  /// Clears the underlying buffer
  void clear() {
    if (_position != 0) {
      throw StateError(
          'MqttByteBuffer::clear - attempt to clear a byte buffer where postion is not zero, it is $_position');
    }
    buffer?.clear();
  }

  /// Cleans(shrink then clear) the buffer
  void clean() {
    shrink();
    clear();
  }

  @override
  String toString() {
    if (buffer == null || buffer!.isEmpty) {
      return 'null or empty';
    } else {
      return buffer!.toList().toString();
    }
  }
}
