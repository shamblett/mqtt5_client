// ignore_for_file: no-magic-number

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The variable header of the unsubscribe acknowledgement message contains  the following fields
/// in the order: packet(message) identifier from the unsubscribe message that is being
/// acknowledged, and properties.
class MqttUnsubscribeAckVariableHeader implements MqttIVariableHeader {
  int _length = 0;

  // Properties
  final _propertySet = MqttPropertyContainer();

  int _messageIdentifier = 0;

  String? _reasonString;

  List<MqttUserProperty> _userProperty = <MqttUserProperty>[];

  /// Receive length
  @override
  int get length => _length;

  /// The message identifier
  int get messageIdentifier => _messageIdentifier;

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String? get reasonString => _reasonString;

  /// User Property.
  ///
  /// This property can be used to provide additional information to the client including
  /// diagnostic information.
  /// The User Property is allowed to appear multiple times to represent multiple name, value pairs.
  /// The same name is allowed to appear more than once.
  List<MqttUserProperty> get userProperty => _userProperty;

  /// Initializes a new instance of the MqttUnsubscribeAckVariableHeader class.
  MqttUnsubscribeAckVariableHeader();

  /// Initializes a new instance of the MqttUnsubscribeAckVariableHeader class.
  MqttUnsubscribeAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
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
      'MqttUnsubscribeAckVariableHeader::writeTo - not implemented, message is receive only',
    );
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

  // Process the properties read from the byte stream
  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
        'MqttUnsubscribeAckVariableHeader::_processProperties, message properties received are invalid',
      );
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
              'MqttUnsubscribeAckVariableHeader::_processProperties, unexpected property type'
              'received, identifier is ${property.identifier}, ignoring',
            );
          }
      }
      _userProperty = _propertySet.userProperties;
    }
  }
}
