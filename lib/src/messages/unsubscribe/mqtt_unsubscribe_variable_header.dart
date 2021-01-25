/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable header of the unsubscribe contains the following
/// fields in the order: packet(message) identifier, and properties.
class MqttUnsubscribeVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttUnsubscribeVariableHeader class.
  MqttUnsubscribeVariableHeader();

  /// The message identifier
  int messageIdentifier = 0;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// The length of the variable header as received
  /// which in this message is always 0;
  /// To get the write length us [getWriteLength]
  @override
  int get length => 0;

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  final _userProperty = <MqttUserProperty>[];
  List<MqttUserProperty> get userProperty => _userProperty;
  set userProperty(List<MqttUserProperty> properties) {
    for (var userProperty in properties) {
      _propertySet.add(userProperty);
    }
    _userProperty.addAll(properties);
  }

  // Serialize the header
  typed.Uint8Buffer? _serialize() {
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    writeMessageIdentifier(stream);
    _propertySet.writeTo(stream);
    return stream.buffer;
  }

  /// Creates a variable header from the specified header stream.
  /// Not implemented, the unsubscribe message is send only.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    throw UnimplementedError(
        'MqttUnubscribeVariableHeader::readFrom - not implemented, message is send only');
  }

  /// Write the message identifier.
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    variableHeaderStream.addAll(_serialize()!);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => _serialize()!.length;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
