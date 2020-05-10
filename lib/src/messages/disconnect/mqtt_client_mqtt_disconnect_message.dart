/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of an MQTT Disconnect Message.
class MqttDisconnectMessage extends MqttMessage {
  /// Initializes a new instance of the MqttDisconnectMessage class.
  MqttDisconnectMessage() {
    header = MqttHeader().asType(MqttMessageType.disconnect);
  }

  /// Initializes a new instance of the MqttDisconnectMessage class.
  MqttDisconnectMessage.fromHeader(MqttHeader header) {
    this.header = header;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    return sb.toString();
  }
}
