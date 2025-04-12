/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// Protocol selection helper class, protocol defaults V5
class MqttProtocol {
  /// Version
  static const int version = MqttConstants.mqttProtocolVersion;

  /// Name
  static const String name = MqttConstants.mqttProtocolName;
}
