/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable Header of the authentication message contains the following fields in
/// the order: authenticate reason code and properties.
class MqttAuthenticateVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttAuthenticateVariableHeader class.
  MqttAuthenticateVariableHeader(this.header);

  /// Initializes a new instance of the MqttAuthenticateVariableHeader class.
  MqttAuthenticateVariableHeader.fromByteBuffer(
      this.header, MqttByteBuffer variableHeaderStream) {
    readFrom(variableHeaderStream);
  }

  /// Standard header
  MqttHeader? header;

  int _length = 0;

  /// The length of the variable header as received.
  /// To get the write length use[getWriteLength].
  @override
  int get length => _length;

  /// Reason code
  MqttAuthenticateReasonCode? reasonCode = MqttAuthenticateReasonCode.notSet;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// Authentication Method
  ///
  ///  A UTF-8 Encoded String containing the name of the authentication method.
  ///  It is a protocol error to omit the authentication method.
  String? _authenticationMethod;
  String? get authenticationMethod => _authenticationMethod;
  set authenticationMethod(String? method) {
    var property =
        MqttUtf8StringProperty(MqttPropertyIdentifier.authenticationMethod);
    property.value = method;
    _propertySet.add(property);
    _authenticationMethod = method;
  }

  /// Authentication Data
  ///
  /// Binary data containing authentication data.
  /// The contents of this data are defined by the authentication method.
  typed.Uint8Buffer _authenticationData = typed.Uint8Buffer();
  typed.Uint8Buffer get authenticationData => _authenticationData;
  set authenticationData(typed.Uint8Buffer data) {
    var property =
        MqttBinaryDataProperty(MqttPropertyIdentifier.authenticationData);
    property.addBytes(data);
    _propertySet.add(property);
    _authenticationData.clear();
    _authenticationData.addAll(data);
  }

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String? _reasonString;
  String? get reasonString => _reasonString;
  set reasonString(String? reason) {
    var property = MqttUtf8StringProperty(MqttPropertyIdentifier.reasonString);
    property.value = reason;
    _propertySet.add(property);
    _reasonString = reason;
  }

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  List<MqttUserProperty> _userProperty = <MqttUserProperty>[];
  List<MqttUserProperty> get userProperty => _userProperty;
  set userProperty(List<MqttUserProperty> properties) {
    for (var userProperty in properties) {
      _propertySet.add(userProperty);
    }
    _userProperty.addAll(properties);
  }

  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
          'MqttAuthenticateVariableHeader::_processProperties, message properties received are invalid');
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        case MqttPropertyIdentifier.authenticationMethod:
          _authenticationMethod = property.value;
          break;
        case MqttPropertyIdentifier.reasonString:
          _reasonString = property.value;
          break;
        case MqttPropertyIdentifier.authenticationData:
          _authenticationData = typed.Uint8Buffer()..addAll(property.value);
          break;
        default:
          if (property.identifier != MqttPropertyIdentifier.userProperty) {
            MqttLogger.log(
                'MqttAuthenticateVariableHeader::_processProperties, unexpected property type'
                'received, identifier is ${property.identifier}, ignoring');
          }
      }
    }
    _userProperty = _propertySet.userProperties.toList();
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    if (header!.messageSize > 1) {
      readReasonCode(variableHeaderStream);
      _length += 1;
      // Properties
      variableHeaderStream.shrink();
      _propertySet.readFrom(variableHeaderStream);
      _length += _propertySet.getWriteLength();
      _processProperties();
      variableHeaderStream.shrink();
    } else {
      reasonCode = MqttAuthenticateReasonCode.success;
    }
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    if (isValid) {
      writeReasonCode(variableHeaderStream);
      _propertySet.writeTo(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    if (isValid) {
      headerLength += _propertySet.getWriteLength() + 1;
    }
    return headerLength;
  }

  /// Reason code.
  void readReasonCode(MqttByteBuffer stream) {
    reasonCode = mqttAuthenticateReasonCode.fromInt(stream.readByte());
  }

  /// Reason code.
  void writeReasonCode(MqttByteBuffer stream) {
    stream.writeByte(mqttAuthenticateReasonCode.asInt(reasonCode));
  }

  /// Is valid.
  /// Reason code must be set and authentication method must be assigned.
  bool get isValid =>
      reasonCode != MqttAuthenticateReasonCode.notSet &&
      authenticationMethod != null;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(
        'Reason Code  = ${mqttAuthenticateReasonCode.asString(reasonCode)}');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
