/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An authenticate message is sent from the client to the broker or the
/// broker to the client as part of an extended authentication exchange,
/// such as challenge / response authentication.
///
/// It is a protocol rror for the client or the broker to send an authentication message
/// if the connect message did not contain the same authentication method.
class MqttAuthenticateMessage extends MqttMessage {
  /// Initializes a new instance of the MqttAuthenticateMessage class.
  MqttAuthenticateMessage() {
    header = MqttHeader().asType(MqttMessageType.auth);
    _variableHeader = MqttAuthenticateVariableHeader(header);
  }

  /// Initializes a new instance of the MqttAuthenticateMessage class from
  /// a supplied header.
  MqttAuthenticateMessage.fromHeader(MqttHeader header) {
    this.header = header;
    _variableHeader = MqttAuthenticateVariableHeader(header);
  }

  /// Initializes a new instance of the MqttAuthenticateMessage class from
  /// a message stream.
  MqttAuthenticateMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  MqttAuthenticateVariableHeader? _variableHeader;

  // Variable header.
  MqttAuthenticateVariableHeader? get variableHeader => _variableHeader;

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    _variableHeader =
        MqttAuthenticateVariableHeader.fromByteBuffer(header, messageStream);
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    final variableHeaderLength = variableHeader!.getWriteLength();
    header!.writeTo(variableHeaderLength, messageStream);
    variableHeader!.writeTo(messageStream);
  }

  /// Sets the reason code of the message.
  MqttAuthenticateMessage withReasonCode(
      MqttAuthenticateReasonCode reasonCode) {
    variableHeader!.reasonCode = reasonCode;
    return this;
  }

  /// Time out indication.
  ///
  /// Used in the re-authentication sequence to indicate the message has been
  /// produced as a result of a timeout.
  /// If this is true on sending an authenticate message validation will fail.
  bool timeout = false;

  /// Gets the reason code of the message.
  MqttAuthenticateReasonCode? get reasonCode => _variableHeader!.reasonCode;

  /// Sets the reason string
  MqttAuthenticateMessage withReasonString(String reason) {
    variableHeader!.reasonString = reason;
    return this;
  }

  /// Gets the reason string.
  String? get reasonString => _variableHeader!.reasonString;

  /// Sets the authentication method.
  MqttAuthenticateMessage withAuthenticationMethod(String method) {
    variableHeader!.authenticationMethod = method;
    return this;
  }

  /// Gets the authentication method.
  String? get authenticationMethod => _variableHeader!.authenticationMethod;

  /// Sets the authentication data.
  MqttAuthenticateMessage withAuthenticationData(typed.Uint8Buffer data) {
    _variableHeader!.authenticationData = data;
    return this;
  }

  /// Gets the authentication data.
  typed.Uint8Buffer get authenticationData =>
      _variableHeader!.authenticationData;

  /// Sets a list of user properties
  MqttAuthenticateMessage withUserProperties(
      List<MqttUserProperty> properties) {
    _variableHeader!.userProperty = properties;
    return this;
  }

  /// Get the user properties
  List<MqttUserProperty> get userProperties => _variableHeader!.userProperty;

  /// Add a specific user property
  void addUserProperty(MqttUserProperty property) {
    _variableHeader!.userProperty = [property];
  }

  /// Is valid
  @override
  bool get isValid => variableHeader!.isValid && !timeout;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(super.toString());
    sb.write(variableHeader.toString());
    return sb.toString();
  }
}
