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
  wildcardSubscriptionsNotSupported,

  /// Not set indication
  notSet
}

/// MQTT reason code support
const Map<int, MqttReasonCode> _mqttReasonCodeValues = <int, MqttReasonCode>{
  0x00: MqttReasonCode.success,
  0x01: MqttReasonCode.grantedQos1,
  0x02: MqttReasonCode.grantedQos2,
  0x04: MqttReasonCode.disconnectWithWillMessage,
  0x10: MqttReasonCode.noMatchingSubscribers,
  0x11: MqttReasonCode.noSubscriptionExisted,
  0x18: MqttReasonCode.continueAuthentication,
  0x19: MqttReasonCode.reauthenticate,
  0x80: MqttReasonCode.unspecifiedError,
  0x81: MqttReasonCode.malformedPacket,
  0x82: MqttReasonCode.protocolError,
  0x83: MqttReasonCode.implementationSpecificError,
  0x84: MqttReasonCode.unsupportedProtocolVersion,
  0x85: MqttReasonCode.clientIdentifierNotValid,
  0x86: MqttReasonCode.badUsernameOrPassword,
  0x87: MqttReasonCode.notAuthorized,
  0x88: MqttReasonCode.serverUnavailable,
  0x89: MqttReasonCode.serverBusy,
  0x8a: MqttReasonCode.banned,
  0x8b: MqttReasonCode.serverShuttingDown,
  0x8c: MqttReasonCode.badAuthenticationMethod,
  0x8d: MqttReasonCode.keepAliveTimeout,
  0x8e: MqttReasonCode.sessionTakenOver,
  0x8f: MqttReasonCode.topicFilterInvalid,
  0x90: MqttReasonCode.topicNameInvalid,
  0x91: MqttReasonCode.packetIdentifierInUse,
  0x92: MqttReasonCode.packetIdentifierNotFound,
  0x93: MqttReasonCode.receiveMaximumExceeded,
  0x94: MqttReasonCode.topicAliasInvalid,
  0x95: MqttReasonCode.packetTooLarge,
  0x96: MqttReasonCode.messageRateTooHigh,
  0x97: MqttReasonCode.quotaExceeded,
  0x98: MqttReasonCode.administrativeAction,
  0x99: MqttReasonCode.payloadFormatInvalid,
  0x9a: MqttReasonCode.retainNotSupported,
  0x9b: MqttReasonCode.qosNotSupported,
  0x9c: MqttReasonCode.useAnotherServer,
  0x9d: MqttReasonCode.serverMoved,
  0x9e: MqttReasonCode.sharedSubscriptionsNotSupported,
  0x9f: MqttReasonCode.connectionRateExceeded,
  0xa0: MqttReasonCode.maximumConnectTime,
  0xa1: MqttReasonCode.subscriptionIdentifiersNotSupported,
  0xa2: MqttReasonCode.wildcardSubscriptionsNotSupported,
  0xff: MqttReasonCode.notSet
};

/// MQTT reason code helper
MqttEnumHelper<MqttReasonCode> mqttReasonCode =
    MqttEnumHelper<MqttReasonCode>(_mqttReasonCodeValues);

/// Utilities class
class ReasonCodeUtilities {
  /// Is the reason code an error. True if an error code or is not set
  static bool isError(int code) => code >= 0x80;
}
