/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Enumeration that indicates various client connection states
enum MqttConnectionState {
  /// The MQTT Connection is in the process of disconnecting from the broker.
  disconnecting,

  /// MQTT Connection is not currently connected to any broker.
  disconnected,

  /// The MQTT Connection is in the process of connecting to the broker.
  connecting,

  /// The MQTT Connection is currently connected to the broker.
  connected,

  /// The MQTT Connection is faulted and no longer communicating
  /// with the broker.
  faulted,
}

/// Enumeration that indicates the origin of a client disconnection
enum MqttDisconnectionOrigin {
  /// Unsolicited, i.e. not requested by the client or the broker.
  /// for example a broker/network failure.
  unsolicited,

  /// Solicited, i.e. requested by the client.
  solicited,

  /// Broker solicited, i.e. requested by the broker sending a disconnect message.
  brokerSolicited,

  /// None set
  none,
}
