/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable header of the subscription acknowledge message contains the following fields
/// in the order: the packet(message) identifier from the subscribe message that is being acknowledged,
/// and properties.
class MqttSubscribeAckVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttSubscribeAckVariableHeader class.
  MqttSubscribeAckVariableHeader();

  /// Initializes a new instance of the MqttSubscribeAckVariableHeader class.
  MqttSubscribeAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  int _length = 0;

  /// Receive length
  @override
  int get length => _length;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// The message identifier
  int _messageIdentifier = 0;
  int get messageIdentifier => _messageIdentifier;

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String? _reasonString;
  String? get reasonString => _reasonString;

  /// User Property.
  ///
  /// This property can be used to provide additional information to the client including
  /// diagnostic information.
  /// The User Property is allowed to appear multiple times to represent multiple name, value pairs.
  /// The same name is allowed to appear more than once.
  List<MqttUserProperty> _userProperty = <MqttUserProperty>[];
  List<MqttUserProperty> get userProperty => _userProperty;

  // Process the properties read from the byte stream
  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
          'MqttSubscribeAckVariableHeader::_processProperties, message properties received are invalid');
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
                'MqttSubscribeAckVariableHeader::_processProperties, unexpected property type'
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
    variableHeaderStream.shrink();
    _propertySet.readFrom(variableHeaderStream);
    _processProperties();
    variableHeaderStream.shrink();
    _length += _propertySet.getWriteLength();
  }

  /// Writes the variable header to the supplied stream.
  /// Not implemented, the message is receive only.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    throw UnimplementedError(
        'MqttSubscribeAckVariableHeader::writeTo - not implemented, message is receive only');
  }

  /// Gets the length of the write data.
  /// Always 0.
  @override
  int getWriteLength() => 0;

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    _messageIdentifier = stream.readShort();
    _length += 2;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Reason String = $reasonString');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
