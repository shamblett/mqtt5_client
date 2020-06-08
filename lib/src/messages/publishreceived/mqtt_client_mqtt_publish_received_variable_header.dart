/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable Header of the publish received message contains the following fields in the
/// order: message identifier from the publish message that is being acknowledged,
/// publish reason code and the properties.
///
class MqttPublishReceivedVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttPublishAckVariableHeader class.
  MqttPublishReceivedVariableHeader(this._header);

  /// Initializes a new instance of the class from a byte buffer.
  MqttPublishReceivedVariableHeader.fromByteBuffer(
      this._header, MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  // The message header
  final _header;
  MqttHeader get header => _header;

  /// The message identifier
  int messageIdentifier = 0;

  /// Publish reason code
  MqttPublishReasonCode reasonCode = MqttPublishReasonCode.notSet;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// The length of the variable header
  @override
  int length = 0;

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String _reasonString;
  String get reasonString => _reasonString;

  /// User Property.
  ///
  /// This property can be used to provide additional information to the client including
  /// diagnostic information.
  /// The User Property is allowed to appear multiple times to represent multiple name, value pairs.
  /// The same name is allowed to appear more than once.
  List<MqttStringPairProperty> _userProperty;
  List<MqttStringPairProperty> get userProperty => _userProperty;

  // Process the properties read from the byte stream
  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
          'MqttPublishReceivedVariableHeader::_processProperties, message properties received are invalid');
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        case MqttPropertyIdentifier.reasonString:
          _reasonString = property.value;
          break;
        default:
          if (property.identifier != MqttPropertyIdentifier.userProperty) {
            MqttLogger.log(
                'MqttPublishReceivedVariableHeader::_processProperties, unexpected property type'
                'received, identifier is ${property.identifier}, ignoring');
          }
      }
      _userProperty = _propertySet.userProperties;
    }
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readMessageIdentifier(variableHeaderStream);
    readReasonCode(variableHeaderStream);
    // Properties
    if (header._messageSize > 4) {
      variableHeaderStream.shrink();
      _propertySet.readFrom(variableHeaderStream);
      _processProperties();
      variableHeaderStream.shrink();
      length += _propertySet.getWriteLength();
    }
  }

  /// Writes a variable header to the supplied message stream.
  /// Not implemented for this message
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    throw UnimplementedError(
        'MqttPublishReceivedVariableHeader::writeTo - Not implemented, message is receive only');
  }

  /// Read the message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Read the reason code.
  void readReasonCode(MqttByteBuffer stream) {
    if (header.messageSize != 2) {
      reasonCode = mqttPublishReasonCode.fromInt(stream.readByte());
      length += 1;
    } else {
      reasonCode = MqttPublishReasonCode.success;
    }
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
