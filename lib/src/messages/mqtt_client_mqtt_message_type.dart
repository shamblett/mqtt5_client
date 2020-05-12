/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An enumeration of all available MQTT Message Types
enum MqttMessageType {
  /// Reserved by the MQTT spec, should not be used.
  reserved1,

  /// Connect
  connect,

  /// Connect acknowledge
  connectAck,

  /// Publish
  publish,

  /// Publish acknowledge
  publishAck,

  /// Publish recieved
  publishReceived,

  /// Publish release
  publishRelease,

  /// Publish complete
  publishComplete,

  /// Subscribe
  subscribe,

  /// Subscribe acknowledge
  subscribeAck,

  /// Unsubscribe
  unsubscribe,

  /// Unsubscribe acknowledge
  unsubscribeAck,

  /// Ping request
  pingRequest,

  /// Ping response
  pingResponse,

  /// Disconnect
  disconnect,

  ///Authentication
  auth
}
