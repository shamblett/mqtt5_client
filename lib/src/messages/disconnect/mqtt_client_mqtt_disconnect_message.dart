/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The disconnect message is the final MQTT Control Packet sent from the client or the broker.
/// It indicates the reason why the network connection is being closed.
/// The client or broker may send a disconnect message before closing the network connection.
///
/// If the network connection is closed without the client first sending a disconnect message
/// with reason code normal disconnection and the connection has a will message,
/// the will message is published.
class MqttDisconnectMessage extends MqttMessage {
  /// Initializes a new instance of the MqttDisconnectMessage class.
  MqttDisconnectMessage() {
    header = MqttHeader().asType(MqttMessageType.disconnect);
    _variableHeader = MqttDisconnectVariableHeader(header);
  }

  /// Initializes a new instance of the MqttDisconnectMessage class.
  MqttDisconnectMessage.fromHeader(MqttHeader header) {
    this.header = header;
    _variableHeader = MqttDisconnectVariableHeader(header);
  }

  MqttDisconnectVariableHeader _variableHeader;
  // Variable header.
  MqttDisconnectVariableHeader get variableHeader => _variableHeader;

  /// Is valid
  @override
  bool get isValid =>
      variableHeader.reasonCode != MqttDisconnectReasonCode.notSet;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(super.toString());
    sb.writeln('${variableHeader.toString()}');
    return sb.toString();
  }
}
