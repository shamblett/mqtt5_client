/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The Variable Header of the publish ack message contains the following fields in the
/// order: message identifier from the publish message that is being acknowledged,
/// publish reason code and the properties.
class MqttPublishAckVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttPublishAckVariableHeader class.
  MqttPublishAckVariableHeader();

  /// Initializes a new instance of the class from a byte buffer.
  MqttPublishAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// The message identifier
  int messageIdentifier = 0;

  /// Publish reason code
  MqttPublishReasonCode reasonCode = MqttPublishReasonCode.notSet;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// The length of the variable header
  @override
  int get length => getWriteLength();
  @override
  set length(int length) {}

  // Process the properties read from the byte stream
  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
          'MqttPublishAckVariableHeader::_processProperties, message properties received are invalid');
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        default:
      }
    }
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readMessageIdentifier(variableHeaderStream);
    readReasonCode(variableHeaderStream);
    // Properties
    variableHeaderStream.shrink();
    _propertySet.readFrom(variableHeaderStream);
    _processProperties();
    variableHeaderStream.shrink();
    length += _propertySet.getWriteLength();
  }

  /// Writes a variable header to the supplied message stream.
  /// Not implemented for this message
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    throw UnimplementedError(
        'MqttPublishAckVariableHeader::writeTo - Not implemented, message is receive only');
  }

  /// Read the message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Read the reason code.
  void readReasonCode(MqttByteBuffer stream) {
    reasonCode = mqttPublishReasonCode.fromInt(stream.readByte());
    length += 1;
  }

  /// Gets the length of the write data when WriteTo will be called.
  /// 0 for this message as [writeTo] is not implemented.
  @override
  int getWriteLength() => 0;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Reason Code = ${mqttPublishReasonCode.asString(reasonCode)}');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
