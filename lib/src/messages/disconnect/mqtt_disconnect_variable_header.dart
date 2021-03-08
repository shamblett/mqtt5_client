/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The variable Header of the disconnect message contains the following fields in the
/// order: disconnect reason code, and properties.
class MqttDisconnectVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttDisconnectVariableHeader class.
  MqttDisconnectVariableHeader(this.header);

  /// Initializes a new instance of the MqttDisconnectVariableHeader class.
  MqttDisconnectVariableHeader.fromByteBuffer(
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
  MqttDisconnectReasonCode? reasonCode = MqttDisconnectReasonCode.notSet;

  // Properties
  final _propertySet = MqttPropertyContainer();

  /// Session Expiry Interval
  ///
  ///  The session expiry interval in seconds.
  int? _sessionExpiryInterval = 0;
  int? get sessionExpiryInterval => _sessionExpiryInterval;
  set sessionExpiryInterval(int? interval) {
    var property = MqttFourByteIntegerProperty(
        MqttPropertyIdentifier.sessionExpiryInterval);
    property.value = interval;
    _propertySet.add(property);
    _sessionExpiryInterval = interval;
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

  /// Server Reference.
  ///
  /// A string to indicate another broker to use.
  String? _serverReference;
  String? get serverReference => _serverReference;
  set serverReference(String? reference) {
    var property =
        MqttUtf8StringProperty(MqttPropertyIdentifier.serverReference);
    property.value = reference;
    _propertySet.add(property);
    _serverReference = reference;
  }

  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
          'MqttDisconnectVariableHeader::_processProperties, message properties received are invalid');
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        case MqttPropertyIdentifier.sessionExpiryInterval:
          _sessionExpiryInterval = property.value;
          break;
        case MqttPropertyIdentifier.reasonString:
          _reasonString = property.value;
          break;
        case MqttPropertyIdentifier.serverReference:
          _serverReference = property.value;
          break;
        default:
          if (property.identifier != MqttPropertyIdentifier.userProperty) {
            MqttLogger.log(
                'MqttDisconnectVariableHeader::_processProperties, unexpected property type'
                'received, identifier is ${property.identifier}, ignoring');
          }
      }
      _userProperty = _propertySet.userProperties;
    }
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
      reasonCode = MqttDisconnectReasonCode.normalDisconnection;
    }
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    if (reasonCode != MqttDisconnectReasonCode.normalDisconnection) {
      writeReasonCode(variableHeaderStream);
      _propertySet.writeTo(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    if (reasonCode != MqttDisconnectReasonCode.normalDisconnection) {
      headerLength += _propertySet.getWriteLength() + 1;
    }
    return headerLength;
  }

  /// Reason code.
  void readReasonCode(MqttByteBuffer stream) {
    reasonCode = mqttDisconnectReasonCode.fromInt(stream.readByte());
  }

  /// Reason code.
  void writeReasonCode(MqttByteBuffer stream) {
    stream.writeByte(mqttDisconnectReasonCode.asInt(reasonCode));
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(
        'Reason Code  = ${mqttDisconnectReasonCode.asString(reasonCode)}');
    sb.write('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
