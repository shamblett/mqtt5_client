/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable header of the publish release message contains the following
/// fields in the order: the message Identifier from the publish receive message
/// that is being acknowledged, reason code, and properties.
class MqttPublishReleaseVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttPublishReleaseVariableHeader class.
  MqttPublishReleaseVariableHeader(this._header);

  /// Initializes a new instance of the class from a byte buffer.
  MqttPublishReleaseVariableHeader.fromByteBuffer(
      this._header, MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  // The message header
  final _header;
  MqttHeader? get header => _header;

  /// The message identifier
  int messageIdentifier = 0;

  /// Publish reason code
  MqttPublishReasonCode? reasonCode = MqttPublishReasonCode.notSet;

  // Properties
  final _propertySet = MqttPropertyContainer();

  int _length = 0;

  /// The length of the variable header as received.
  /// To get the write length us [getWriteLength]
  @override
  int get length => _length;

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String? _reasonString;
  String? get reasonString => _reasonString;
  set reasonString(String? reason) {
    final property =
        MqttUtf8StringProperty(MqttPropertyIdentifier.reasonString);
    property.value = reason;
    _propertySet.add(property);
    _reasonString = reason;
  }

  /// User Property.
  ///
  /// This property can be used to provide additional information to the client including
  /// diagnostic information.
  /// The User Property is allowed to appear multiple times to represent multiple name, value pairs.
  /// The same name is allowed to appear more than once.
  List<MqttUserProperty> _userProperty = <MqttUserProperty>[];
  List<MqttUserProperty> get userProperty => _userProperty;
  set userProperty(List<MqttUserProperty> properties) {
    for (var property in properties) {
      _propertySet.add(property);
      _userProperty.add(property);
    }
  }

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
    if (header!._messageSize > 4) {
      variableHeaderStream.shrink();
      _propertySet.readFrom(variableHeaderStream);
      _processProperties();
      variableHeaderStream.shrink();
      _length += _propertySet.getWriteLength();
    }
  }

  // Serialize the header
  typed.Uint8Buffer? _serialize() {
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    writeMessageIdentifier(stream);
    // If there are no properties and the reason code is success
    // we can end here.
    if (reasonCode == MqttPublishReasonCode.success && _propertySet.isEmpty) {
    } else {
      writeReasonCode(stream);
      _propertySet.writeTo(stream);
    }

    return stream.buffer;
  }

  /// Writes a variable header to the supplied message stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    variableHeaderStream.addAll(_serialize()!);
  }

  /// Read the message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    _length += 2;
  }

  /// Read the reason code.
  void readReasonCode(MqttByteBuffer stream) {
    if (header!.messageSize != 2) {
      reasonCode = mqttPublishReasonCode.fromInt(stream.readByte());
      _length += 1;
    } else {
      reasonCode = MqttPublishReasonCode.success;
    }
  }

  /// Write the message identifier.
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  /// Write the reason code
  void writeReasonCode(MqttByteBuffer stream) {
    stream.writeByte(mqttPublishReasonCode.asInt(reasonCode));
  }

  /// Gets the length of the write data.
  @override
  int getWriteLength() => _serialize()!.length;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Reason Code = ${mqttPublishReasonCode.asString(reasonCode)}');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
