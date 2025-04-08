/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The disconnect message is the final MQTT Control Packet sent from the client or the broker.
/// It indicates the reason why the network connection is being closed.
/// The client or broker may send a disconnect message before closing the network connection.
///
/// If the network connection is closed without the client first sending a disconnect message
/// with reason code normal disconnection and the connection has a will message,
/// the will message is published.
class MqttDisconnectMessage extends MqttMessage {
  MqttDisconnectVariableHeader? _variableHeader;

  /// Variable header.
  MqttDisconnectVariableHeader? get variableHeader => _variableHeader;

  /// Gets the reason code of the message.
  MqttDisconnectReasonCode? get reasonCode => _variableHeader!.reasonCode;

  /// Gets the session expiry interval.
  int? get sessionExpiryInterval => _variableHeader!.sessionExpiryInterval;

  /// Gets the reason string
  String? get reasonString => _variableHeader!.reasonString;

  /// Gets the server reference.
  String? get serverReference => _variableHeader!.serverReference;

  /// Get the user properties
  List<MqttUserProperty> get userProperties => _variableHeader!.userProperty;

  /// Is valid
  @override
  bool get isValid =>
      variableHeader!.reasonCode != MqttDisconnectReasonCode.notSet;

  /// Initializes a new instance of the MqttDisconnectMessage class.
  MqttDisconnectMessage() {
    header = MqttHeader().asType(MqttMessageType.disconnect);
    _variableHeader = MqttDisconnectVariableHeader(header);
  }

  /// Initializes a new instance of the MqttDisconnectMessage class from
  /// a supplied header.
  MqttDisconnectMessage.fromHeader(MqttHeader header) {
    this.header = header;
    _variableHeader = MqttDisconnectVariableHeader(header);
  }

  /// Initializes a new instance of the MqttDisconnectMessage class from
  /// a message stream.
  MqttDisconnectMessage.fromByteBuffer(
    MqttHeader header,
    MqttByteBuffer messageStream,
  ) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Sets the session expiry interval.
  MqttDisconnectMessage withSessionExpiryInterval(int interval) {
    variableHeader!.sessionExpiryInterval = interval;
    return this;
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    _variableHeader = MqttDisconnectVariableHeader.fromByteBuffer(
      header,
      messageStream,
    );
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    final variableHeaderLength = variableHeader!.getWriteLength();
    header!.writeTo(variableHeaderLength, messageStream);
    variableHeader!.writeTo(messageStream);
  }

  /// Sets the reason code of the message.
  MqttDisconnectMessage withReasonCode(MqttDisconnectReasonCode reasonCode) {
    variableHeader!.reasonCode = reasonCode;
    return this;
  }

  /// Sets the reason string
  MqttDisconnectMessage withReasonString(String reason) {
    variableHeader!.reasonString = reason;
    return this;
  }

  /// Sets the server reference.
  MqttDisconnectMessage withServerReference(String reference) {
    variableHeader!.serverReference = reference;
    return this;
  }

  /// Sets a list of user properties
  MqttDisconnectMessage withUserProperties(List<MqttUserProperty> properties) {
    _variableHeader!.userProperty = properties;
    return this;
  }

  /// Add a specific user property
  void addUserProperty(MqttUserProperty property) {
    _variableHeader!.userProperty = [property];
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(super.toString());
    sb.write(variableHeader.toString());
    return sb.toString();
  }
}
