/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Protocol selection helper class, protocol defaults V3.1
class Protocol {
  /// Version
  static int version = MqttClientConstants.mqttV31ProtocolVersion;

  /// Name
  static String name = MqttClientConstants.mqttV31ProtocolName;
}
