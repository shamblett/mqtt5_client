/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The variable Header of the subscribe message contains the following fields in the order:
/// Packet(message) identifier, and properties.
class MqttSubscribeVariableHeader implements MqttIVariableHeader {
  /// The message identifier
  int messageIdentifier = 0;

  // Properties
  final _propertySet = MqttPropertyContainer();

  int _subscriptionIdentifier = 0;

  final _userProperty = <MqttUserProperty>[];

  /// The length of the variable header as received
  /// which in this message is always 0;
  /// To get the write length us [getWriteLength]
  @override
  int get length => 0;

  /// Subscription Identifier
  ///
  /// The identifier of the subscription.
  /// The subscription identifier can have the value of 1 to 268,435,455.
  int get subscriptionIdentifier => _subscriptionIdentifier;

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  List<MqttUserProperty> get userProperty => _userProperty;

  set userProperty(List<MqttUserProperty>? properties) {
    if (properties != null) {
      for (var userProperty in properties) {
        _propertySet.add(userProperty);
      }
      _userProperty.addAll(properties);
    }
  }

  set subscriptionIdentifier(identifier) {
    if (identifier < 1 || identifier > MqttConstants.maxMessageSize) {
      throw ArgumentError(
        'MqttSubscribeVariableHeader::subscriptionIdentifier identifier is invalid',
      );
    }
    final property = MqttVariableByteIntegerProperty(
      MqttPropertyIdentifier.subscriptionIdentifier,
    );
    property.value = identifier;
    _propertySet.add(property);
    _subscriptionIdentifier = identifier;
  }

  /// Initializes a new instance of the MqttSubscribeVariableHeader class.
  MqttSubscribeVariableHeader();

  /// Creates a variable header from the specified header stream.
  /// Not implemented, the subscribe message is send only.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    throw UnimplementedError(
      'MqttSubscribeVariableHeader::readFrom - not implemented, message is send only',
    );
  }

  /// Write the message identifier.
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  /// Writes a variable header to the supplied message stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    variableHeaderStream.addAll(_serialize()!);
  }

  /// Gets the length of the write data.
  @override
  int getWriteLength() => _serialize()!.length;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Subscription identifier = $subscriptionIdentifier');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }

  // Serialize the header
  typed.Uint8Buffer? _serialize() {
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    writeMessageIdentifier(stream);
    _propertySet.writeTo(stream);
    return stream.buffer;
  }
}
