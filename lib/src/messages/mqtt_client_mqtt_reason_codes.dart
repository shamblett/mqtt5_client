/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// MQTT reason code
///
/// A Reason Code is a one byte unsigned value that indicates the result of an operation.
/// Reason Codes less than 0x80 indicate successful completion of an operation.
/// The normal Reason Code for success is 0.
/// Reason Code values of 0x80 or greater indicate failure.
enum MqttReasonCode {
  /// Success/Normal disconnection/Granted QoS 0
  success,

  /// Granted QoS 1
  grantedQos1,

  /// Granted QoS 2
  grantedQos2,

  /// Disconnect with Will Message
  disconnectWithWillMessage,

  /// No matching subscribers
  noMatchingSubscribers,

  /// No subscription existed
  noSubscriptionExisted,

  /// Continue authentication
  continueAuthentication,

  /// Re-authenticate
  reauthenticate,

  /// Unspecified error
  unspecifiedError,

  /// Malformed Packet
  malformedPacket,

  /// Protocol Error
  protocolError,

  /// Implementation specific error
  implementationSpecificError,

  /// Unsupported Protocol Version
  unsupportedProtocolVersion,

  /// Client Identifier not valid
  clientIdentifierNotValid,

  /// Bad User Name or Password
  badUsernameOrPassword,

  /// Not authorized
  notAuthorized,

  /// Server unavailable
  serverUnavailable,

  /// Server busy
  serverBusy,

  /// Banned
  banned,

  /// Server shutting down
  serverShuttingDown,

  /// Bad authentication method
  badAuthenticationMethod,

  /// Keep Alive timeout
  keepAliveTimeout,

  /// Session taken over
  sessionTakenOver,

  /// Topic Filter invalid
  topicFilterInvalid,

  /// Topic Name invalid
  topicNameInvalid,

  /// Packet Identifier in use
  packetIdentifierInUse,

  /// Packet Identifier not found
  packetIdentifierNotFound,

  /// Receive Maximum exceeded
  receiveMaximumExceeded,

  /// Topic Alias invalid
  topicAliasInvalid,

  /// Packet too large
  packetTooLarge,

  /// Message rate too high
  messageRateTooHigh,

  /// Quota exceeded
  quotaExceeded,

  /// Administrative action
  administrativeAction,

  /// Payload format invalid
  payloadFormatInvalid,

  /// Retain not supported
  retainNotSupported,

  /// QoS not supported
  qosNotSupported,

  /// Use another server
  useAnotherServer,

  /// Server moved
  serverMoved,

  /// Shared Subscriptions not supported
  sharedSubscriptionsNotSupported,

  /// Connection rate exceeded
  connectionRateExceeded,

  /// Maximum connect time
  maximumConnectTime,

  /// Subscription Identifiers not supported
  subscriptionIdentifiersNotSupported,

  /// Wildcard Subscriptions not supported
  wildcardSubscriptionsNotSupported
}

/// MQTT reason code support
const Map<int, MqttReasonCode> _mqttReasonCodeValues = <int, MqttReasonCode>{};

/// MQTT reason code helper
MqttEnumHelper<MqttReasonCode> mqttReasonCode =
    MqttEnumHelper<MqttReasonCode>(_mqttReasonCodeValues);

/// Utilities class
class ReasonCodeUtilities {
  /// Is the reason code an error. True if an error code
  static bool isError(int code) => code >= 0x80;
}
