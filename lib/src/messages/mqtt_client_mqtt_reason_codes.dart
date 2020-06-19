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
/// Reason codes less than 0x80 indicate successful completion of an operation.
/// The normal Reason Code for success is 0.
/// Reason Code values of 0x80 or greater indicate failure.

/// Connect message processing reason codes.
enum MqttConectReasonCode {
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

  /// client Identifier not valid
  clientIdentifierNotValid,

  /// Bad User Name or Password
  badUsernameOrPassword,

  /// Not authorized
  notAuthorized,

  /// broker unavailable
  serverUnavailable,

  /// broker busy
  serverBusy,

  /// Banned
  banned,

  /// broker shutting down
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
  messageIdentifierInUse,

  /// Packet Identifier not found
  messageIdentifierNotFound,

  /// Receive Maximum exceeded
  receiveMaximumExceeded,

  /// Topic Alias invalid
  topicAliasInvalid,

  /// Packet too large
  messageTooLarge,

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
  useAnotherbroker,

  /// broker moved
  serverMoved,

  /// Shared Subscriptions not supported
  sharedSubscriptionsNotSupported,

  /// connection rate exceeded
  connectionRateExceeded,

  /// Maximum connect time
  maximumConnectTime,

  /// Subscription Identifiers not supported
  subscriptionIdentifiersNotSupported,

  /// Wildcard Subscriptions not supported
  wildcardSubscriptionsNotSupported,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT connect reason code support
const Map<int, MqttConectReasonCode> _mqttConnectReasonCodeValues =
    <int, MqttConectReasonCode>{
  0x00: MqttConectReasonCode.success,
  0x01: MqttConectReasonCode.grantedQos1,
  0x02: MqttConectReasonCode.grantedQos2,
  0x04: MqttConectReasonCode.disconnectWithWillMessage,
  0x10: MqttConectReasonCode.noMatchingSubscribers,
  0x11: MqttConectReasonCode.noSubscriptionExisted,
  0x18: MqttConectReasonCode.continueAuthentication,
  0x19: MqttConectReasonCode.reauthenticate,
  0x80: MqttConectReasonCode.unspecifiedError,
  0x81: MqttConectReasonCode.malformedPacket,
  0x82: MqttConectReasonCode.protocolError,
  0x83: MqttConectReasonCode.implementationSpecificError,
  0x84: MqttConectReasonCode.unsupportedProtocolVersion,
  0x85: MqttConectReasonCode.clientIdentifierNotValid,
  0x86: MqttConectReasonCode.badUsernameOrPassword,
  0x87: MqttConectReasonCode.notAuthorized,
  0x88: MqttConectReasonCode.serverUnavailable,
  0x89: MqttConectReasonCode.serverBusy,
  0x8a: MqttConectReasonCode.banned,
  0x8b: MqttConectReasonCode.serverShuttingDown,
  0x8c: MqttConectReasonCode.badAuthenticationMethod,
  0x8d: MqttConectReasonCode.keepAliveTimeout,
  0x8e: MqttConectReasonCode.sessionTakenOver,
  0x8f: MqttConectReasonCode.topicFilterInvalid,
  0x90: MqttConectReasonCode.topicNameInvalid,
  0x91: MqttConectReasonCode.messageIdentifierInUse,
  0x92: MqttConectReasonCode.messageIdentifierNotFound,
  0x93: MqttConectReasonCode.receiveMaximumExceeded,
  0x94: MqttConectReasonCode.topicAliasInvalid,
  0x95: MqttConectReasonCode.messageTooLarge,
  0x96: MqttConectReasonCode.messageRateTooHigh,
  0x97: MqttConectReasonCode.quotaExceeded,
  0x98: MqttConectReasonCode.administrativeAction,
  0x99: MqttConectReasonCode.payloadFormatInvalid,
  0x9a: MqttConectReasonCode.retainNotSupported,
  0x9b: MqttConectReasonCode.qosNotSupported,
  0x9c: MqttConectReasonCode.useAnotherbroker,
  0x9d: MqttConectReasonCode.serverMoved,
  0x9e: MqttConectReasonCode.sharedSubscriptionsNotSupported,
  0x9f: MqttConectReasonCode.connectionRateExceeded,
  0xa0: MqttConectReasonCode.maximumConnectTime,
  0xa1: MqttConectReasonCode.subscriptionIdentifiersNotSupported,
  0xa2: MqttConectReasonCode.wildcardSubscriptionsNotSupported,
  0xff: MqttConectReasonCode.notSet
};

/// MQTT connect reason code helper
MqttEnumHelper<MqttConectReasonCode> mqttConnectReasonCode =
    MqttEnumHelper<MqttConectReasonCode>(_mqttConnectReasonCodeValues);

/// Publish message processing reason codes.
enum MqttPublishReasonCode {
  /// The message is accepted.
  /// Publication of the QoS 1 message proceeds.
  success,

  /// The message is accepted but there are no subscribers.
  /// This is sent only by the broker If the broker knows that
  /// there are no matching subscribers, it MAY use this reason dode instead
  /// of success.
  noMatchingSubscribers,

  /// The receiver does not accept the publish but either does not want to
  /// reveal the reason, or it does not match one of the other values.
  unspecifiedError,

  /// The publish is valid but the receiver is not willing to accept it.
  implementationSpecificError,

  /// The publish is not authorized.
  notAuthorized,

  /// The Topic Name is not malformed, but is not accepted by
  /// the client or broker.
  topicNameInvalid,

  /// The packet(message) identifier is already in use. This might indicate a
  /// mismatch in the session state between the client and the broker.
  packetIdentifierInUse,

  /// The packet(message) identifier is not known. This is not an error during recovery,
  /// but at other times indicates a mismatch between
  /// the session state on the client and broker.
  packetIdentifierNotFound,

  /// An implementation or administrative imposed limit has been exceeded.
  quotaExceeded,

  /// The payload format does not match the specified payload
  /// format indicator.
  payloadFormatInvalid,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT publish reason code support
const Map<int, MqttPublishReasonCode> _mqttPublishReasonCodeValues =
    <int, MqttPublishReasonCode>{
  0x00: MqttPublishReasonCode.success,
  0x10: MqttPublishReasonCode.noMatchingSubscribers,
  0x80: MqttPublishReasonCode.unspecifiedError,
  0x83: MqttPublishReasonCode.implementationSpecificError,
  0x87: MqttPublishReasonCode.notAuthorized,
  0x90: MqttPublishReasonCode.topicNameInvalid,
  0x91: MqttPublishReasonCode.packetIdentifierInUse,
  0x92: MqttPublishReasonCode.packetIdentifierNotFound,
  0x97: MqttPublishReasonCode.quotaExceeded,
  0x99: MqttPublishReasonCode.payloadFormatInvalid,
  0xff: MqttPublishReasonCode.notSet
};

/// MQTT publish reason code helper
MqttEnumHelper<MqttPublishReasonCode> mqttPublishReasonCode =
    MqttEnumHelper<MqttPublishReasonCode>(_mqttPublishReasonCodeValues);

/// Subscribe message processing reason codes. Also contains codes only used by
/// the unsubscribe ack message, these are commented appropriately.
enum MqttSubscribeReasonCode {
  /// The subscription is accepted and the maximum QoS sent will be QoS 0.
  /// This might be a lower QoS than was requested. Note that when used in
  /// the unsubscribe ack message this value indicates success.
  grantedQos0,

  /// The subscription is accepted and the maximum QoS sent will be QoS 1.
  /// This might be a lower QoS than was requested.
  grantedQos1,

  /// The subscription is accepted and any received QoS will be
  /// sent to this subscription.
  grantedQos2,

  /// No matching topic filter is being used by the client.
  /// Used only by the unsubscribe ack message.
  noSubscriptionExisted,

  /// The subscription is not accepted and the broker either does not wish to reveal
  /// the reason or none of the other reason codes apply.
  unspecifiedError,

  /// The subscribe is valid but the broker does not accept it.
  implementationSpecificError,

  /// The client is not authorized to make this subscription.
  notAuthorized,

  /// The topic filter is correctly formed but is not allowed
  /// for this client.
  topicFilterInvalid,

  /// The specified packet(message) identifier is already in use.
  packetIdentifierInUse,

  /// An implementation or administrative imposed limit has been exceeded.
  quotaExceeded,

  /// The broker does not support shared subscriptions for this client.
  sharedSubscriptionsNotSupported,

  /// The broker does not support subscription identifiers;
  /// the subscription is not accepted.
  subscriptionIdentifiersNotSupported,

  /// The broker does not support wildcard Subscriptions;
  /// the subscription is not accepted.
  wildcardSubscriptionsNotSupported
}

/// MQTT subscribe reason code support
const Map<int, MqttSubscribeReasonCode> _mqttSubscribeReasonCodeValues =
    <int, MqttSubscribeReasonCode>{
  0x00: MqttSubscribeReasonCode.grantedQos0,
  0x01: MqttSubscribeReasonCode.grantedQos1,
  0x02: MqttSubscribeReasonCode.grantedQos2,
  0x11: MqttSubscribeReasonCode.noSubscriptionExisted,
  0x80: MqttSubscribeReasonCode.unspecifiedError,
  0x83: MqttSubscribeReasonCode.implementationSpecificError,
  0x87: MqttSubscribeReasonCode.notAuthorized,
  0x8f: MqttSubscribeReasonCode.topicFilterInvalid,
  0x91: MqttSubscribeReasonCode.packetIdentifierInUse,
  0x97: MqttSubscribeReasonCode.quotaExceeded,
  0x9e: MqttSubscribeReasonCode.sharedSubscriptionsNotSupported,
  0xa1: MqttSubscribeReasonCode.subscriptionIdentifiersNotSupported,
  0xa2: MqttSubscribeReasonCode.wildcardSubscriptionsNotSupported
};

/// MQTT dubscribe reason code helper
MqttEnumHelper<MqttSubscribeReasonCode> mqttSubscribeReasonCode =
    MqttEnumHelper<MqttSubscribeReasonCode>(_mqttSubscribeReasonCodeValues);

/// Utilities class
class MqttReasonCodeUtilities {
  /// Is the reason code an error. True if an error code or is not set.
  static bool isError(int code) => code >= 0x80;
}
