/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// Records the status of the last connection attempt.
class MqttConnectionStatus {
  /// Connection state
  MqttConnectionState state = MqttConnectionState.disconnected;

  /// Reason Code from [connectAckMessage]
  MqttConnectReasonCode? reasonCode = MqttConnectReasonCode.notSet;

  /// Reason String from [connectAckMessage]
  String? reasonString;

  /// Disconnection origin
  MqttDisconnectionOrigin disconnectionOrigin = MqttDisconnectionOrigin.none;

  /// The last Connect acknowledgement message as
  /// received.
  late MqttConnectAckMessage connectAckMessage;

  /// The last disconnect message received from the broker.
  late MqttDisconnectMessage disconnectMessage;

  @override
  String toString() {
    final s = state.toString().split('.')[1];
    final r = MqttConnectReasonCodeSupport.mqttConnectReasonCode.asString(
      reasonCode,
    );
    final t = disconnectionOrigin.toString().split('.')[1];
    return 'Connection status is $s with return code of $r and a disconnection origin of $t';
  }
}
