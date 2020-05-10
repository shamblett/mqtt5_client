/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Enumeration of allowable connection request return codes from a broker.
enum MqttConnectReturnCode {
  /// Connection accepted
  connectionAccepted,

  /// Invalid protocol version
  unacceptedProtocolVersion,

  /// Invalid client identifier
  identifierRejected,

  /// Broker unavailable
  brokerUnavailable,

  /// Invalid username or password
  badUsernameOrPassword,

  /// Not authorised
  notAuthorized,

  /// Default
  noneSpecified
}
