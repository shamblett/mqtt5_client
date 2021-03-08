/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Represents an MQTT message that contains a fixed header, variable
/// header and message body.
///
/// Messages roughly look as follows.
/// ----------------------------
/// | Header, 2-5 Bytes Length |
/// ----------------------------
/// | Variable Header(VH)      |
/// | n Bytes Length           |
/// ----------------------------
/// | Message Payload          |
/// | 256MB minus VH Size      |
/// ----------------------------

class MqttMessage {
  /// Initializes a new instance of the MqttMessage class.
  MqttMessage();

  /// Initializes a new instance of the MqttMessage class.
  MqttMessage.fromHeader(this.header);

  /// The header of the MQTT Message. Contains metadata about the message
  MqttHeader? header;

  /// Creates a new instance of an MQTT Message based on a raw message stream.
  static MqttMessage? createFrom(MqttByteBuffer messageStream) {
    try {
      var header = MqttHeader();
      // Pass the input stream sequentially through the component
      // deserialization(create) methods to build a full MqttMessage.
      header = MqttHeader.fromByteBuffer(messageStream);

      if (messageStream.availableBytes < header.messageSize) {
        messageStream.reset();
        throw MqttInvalidMessageException(
            'Available bytes is less than the message size');
      }
      final message = MqttMessageFactory.getMessage(header, messageStream);
      return message;
    } on Exception catch (e) {
      throw MqttInvalidMessageException(
          'The data provided in the message stream was not a '
          'valid MQTT Message, '
          'exception is $e, bytestream is $messageStream');
    }
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(0, messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {}

  /// Is valid
  bool get isValid => true;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('MQTTMessage of type ');
    sb.writeln(header!.messageType.toString());
    sb.writeln(header.toString());
    return sb.toString();
  }
}
