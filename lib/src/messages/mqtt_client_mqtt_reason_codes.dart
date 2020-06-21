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
enum MqttConnectReasonCode {
  /// The connection is accepted.
  success,

  /// The broker does not wish to reveal the reason for the failure,
  /// or none of the other reason codes apply.
  unspecifiedError,

  /// Data within the connect message could not be correctly parsed.
  malformedPacket,

  /// Data in the connect message does not conform to this specification.
  protocolError,

  /// The connect message is valid but is not accepted by this broker.
  implementationSpecificError,

  /// The broker does not support the version of the MQTT protocol
  /// requested by the client.
  unsupportedProtocolVersion,

  /// The client identifier is a valid string but is not allowed by the broker.
  clientIdentifierNotValid,

  /// The broker does not accept the user name or password specified
  /// by the client
  badUsernameOrPassword,

  /// The client is not authorized to connect.
  notAuthorized,

  /// The MQTT broker is not available.
  serverUnavailable,

  /// The broker is busy. Try again later.
  serverBusy,

  /// This client has been banned by administrative action.
  /// Contact the server administrator.
  banned,

  /// The authentication method is not supported or does not match
  /// the authentication method currently in use.
  badAuthenticationMethod,

  /// The will topic name is not malformed, but is not accepted by this broker.
  topicNameInvalid,

  /// The connect packet(message) exceeded the maximum permissible size.
  packetTooLarge,

  /// An implementation or administrative imposed limit has been exceeded.
  quotaExceeded,

  /// The will payload does not match the specified payload format indicator.
  payloadFormatInvalid,

  /// The broker does not support retained messages, and will
  /// retain was set to true.
  retainNotSupported,

  /// The broker does not support the QoS set in will QoS.
  qosNotSupported,

  /// The client should temporarily use another broker.
  useAnotherServer,

  /// The client should permanently use another broker.
  serverMoved,

  /// The connection rate limit has been exceeded.
  connectionRateExceeded,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT connect reason code support
const Map<int, MqttConnectReasonCode> _mqttConnectReasonCodeValues =
    <int, MqttConnectReasonCode>{
  0x00: MqttConnectReasonCode.success,
  0x80: MqttConnectReasonCode.unspecifiedError,
  0x81: MqttConnectReasonCode.malformedPacket,
  0x82: MqttConnectReasonCode.protocolError,
  0x83: MqttConnectReasonCode.implementationSpecificError,
  0x84: MqttConnectReasonCode.unsupportedProtocolVersion,
  0x85: MqttConnectReasonCode.clientIdentifierNotValid,
  0x86: MqttConnectReasonCode.badUsernameOrPassword,
  0x87: MqttConnectReasonCode.notAuthorized,
  0x88: MqttConnectReasonCode.serverUnavailable,
  0x89: MqttConnectReasonCode.serverBusy,
  0x8a: MqttConnectReasonCode.banned,
  0x8c: MqttConnectReasonCode.badAuthenticationMethod,
  0x90: MqttConnectReasonCode.topicNameInvalid,
  0x95: MqttConnectReasonCode.packetTooLarge,
  0x97: MqttConnectReasonCode.quotaExceeded,
  0x99: MqttConnectReasonCode.payloadFormatInvalid,
  0x9a: MqttConnectReasonCode.retainNotSupported,
  0x9b: MqttConnectReasonCode.qosNotSupported,
  0x9c: MqttConnectReasonCode.useAnotherServer,
  0x9d: MqttConnectReasonCode.serverMoved,
  0x9f: MqttConnectReasonCode.connectionRateExceeded,
  0xff: MqttConnectReasonCode.notSet
};

/// MQTT connect reason code helper
MqttEnumHelper<MqttConnectReasonCode> mqttConnectReasonCode =
    MqttEnumHelper<MqttConnectReasonCode>(_mqttConnectReasonCodeValues);

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

/// MQTT subscribe reason code helper
MqttEnumHelper<MqttSubscribeReasonCode> mqttSubscribeReasonCode =
    MqttEnumHelper<MqttSubscribeReasonCode>(_mqttSubscribeReasonCodeValues);

/// Disconnect message processing reason codes.
enum MqttDisconnectReasonCode {
  /// Close the connection normally. Do not send the will message.
  normalDisconnection,

  /// The client wishes to disconnect but requires that the broker also
  /// publishes its will message.
  disconnectWithWillMessage,

  /// The connection is closed but the sender either does not wish to reveal the reason,
  /// or none of the other reason codes apply.
  unspecifiedError,

  /// The received packet does not conform to this specification.
  malformedPacket,

  /// An unexpected or out of order packet was received.
  protocolError,

  /// The message received is valid but cannot be processed by this implementation.
  implementationSpecificError,

  /// The request is not authorized.
  notAuthorized,

  /// The broker is busy and cannot continue processing requests from this client.
  serverBusy,

  /// The broker is shutting down.
  serverShuttingDown,

  /// The connection is closed because no packet has been received for
  /// 1.5 times the keep alive time.
  keepAliveTimeout,

  /// Another connection using the same client ID has connected causing
  /// this connection to be closed.
  sessionTakenOver,

  /// The topic filter is correctly formed, but is not accepted
  /// by this broker.
  topicFilterInvalid,

  /// The topic name is correctly formed, but is not accepted by this
  /// client or broker.
  topicNameInvalid,

  /// The client or broker has received more than receive maximum publication
  /// for which it has not sent a publish acnowlwdge or publish complete message.
  receiveMaximumExceeded,

  /// The client or broker has received a publish message containing a topic
  /// alias which is greater than the maximum topic alias it sent in the
  /// connect or connect acknowledge message.
  topicAliasInvalid,

  /// The packet(message) size is greater than maximum message size for this
  /// client or broker.
  packetTooLarge,

  /// The received data rate is too high.
  messageRateTooHigh,

  /// An implementation or administrative imposed limit has been exceeded.
  quotaExceeded,

  /// The Connection is closed due to an administrative action.
  administrativeAction,

  /// The payload format does not match the one specified by the
  /// payload format indicator.
  payloadFormatInvalid,

  /// The broker does not support retained messages.
  retainNotSupported,

  /// The client specified a QoS greater than the QoS specified in a
  /// maximum QoS in the connection acknowledge message.
  qosNotSupported,

  /// The client should temporarily change its broker.
  useAnotherServer,

  /// The broker is moved and the client should permanently change its broker location.
  serverMoved,

  /// The broker does not support shared subscriptions.
  sharedSubscriptionsNotSupported,

  /// This connection is closed because the connection rate is too high.
  connectionRateExceeded,

  /// The maximum connection time authorized for this connection has been exceeded.
  maximumConnectTime,

  /// The broker does not support subscription identifiers;
  /// the subscription is not accepted.
  subscriptionIdentifiersNotSupported,

  /// The broker does not support Wildcard Subscriptions;
  /// the subscription is not accepted.
  wildcardSubscriptionsNotSupported,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT disconnect reason code support
const Map<int, MqttDisconnectReasonCode> _mqttDisconnectReasonCodeValues =
    <int, MqttDisconnectReasonCode>{
  0x00: MqttDisconnectReasonCode.normalDisconnection,
  0x04: MqttDisconnectReasonCode.disconnectWithWillMessage,
  0x80: MqttDisconnectReasonCode.unspecifiedError,
  0x81: MqttDisconnectReasonCode.malformedPacket,
  0x82: MqttDisconnectReasonCode.protocolError,
  0x83: MqttDisconnectReasonCode.implementationSpecificError,
  0x87: MqttDisconnectReasonCode.notAuthorized,
  0x89: MqttDisconnectReasonCode.serverBusy,
  0x8b: MqttDisconnectReasonCode.serverShuttingDown,
  0x8d: MqttDisconnectReasonCode.keepAliveTimeout,
  0x8e: MqttDisconnectReasonCode.sessionTakenOver,
  0x8f: MqttDisconnectReasonCode.topicFilterInvalid,
  0x90: MqttDisconnectReasonCode.topicNameInvalid,
  0x93: MqttDisconnectReasonCode.receiveMaximumExceeded,
  0x94: MqttDisconnectReasonCode.topicAliasInvalid,
  0x95: MqttDisconnectReasonCode.packetTooLarge,
  0x96: MqttDisconnectReasonCode.messageRateTooHigh,
  0x97: MqttDisconnectReasonCode.quotaExceeded,
  0x98: MqttDisconnectReasonCode.administrativeAction,
  0x99: MqttDisconnectReasonCode.payloadFormatInvalid,
  0x9a: MqttDisconnectReasonCode.retainNotSupported,
  0x9b: MqttDisconnectReasonCode.qosNotSupported,
  0x9c: MqttDisconnectReasonCode.useAnotherServer,
  0x9d: MqttDisconnectReasonCode.serverMoved,
  0x9e: MqttDisconnectReasonCode.sharedSubscriptionsNotSupported,
  0x9f: MqttDisconnectReasonCode.connectionRateExceeded,
  0xa0: MqttDisconnectReasonCode.maximumConnectTime,
  0xa1: MqttDisconnectReasonCode.subscriptionIdentifiersNotSupported,
  0xa2: MqttDisconnectReasonCode.wildcardSubscriptionsNotSupported,
  0xff: MqttDisconnectReasonCode.notSet
};

/// MQTT disconnect reason code helper
MqttEnumHelper<MqttDisconnectReasonCode> mqttDisconnectReasonCode =
    MqttEnumHelper<MqttDisconnectReasonCode>(_mqttDisconnectReasonCodeValues);

/// Authentication message processing reason codes.
enum MqttAuthenticateReasonCode {
  /// Authentication is successful
  success,

  /// Continue the authentication with another step.
  continueAuthentication,

  /// Initiate a re-authentication.
  reAuthenticate,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT authenticate reason code support
const Map<int, MqttAuthenticateReasonCode> _mqttAuthenticateReasonCodeValues =
    <int, MqttAuthenticateReasonCode>{
  0x00: MqttAuthenticateReasonCode.success,
  0x18: MqttAuthenticateReasonCode.continueAuthentication,
  0x19: MqttAuthenticateReasonCode.reAuthenticate,
  0x0ff: MqttAuthenticateReasonCode.notSet
};

// MQTT authenticate reason code helper
MqttEnumHelper<MqttAuthenticateReasonCode> mqttAuthenticateReasonCode =
    MqttEnumHelper<MqttAuthenticateReasonCode>(
        _mqttAuthenticateReasonCodeValues);

/// Utilities class
class MqttReasonCodeUtilities {
  /// Is the reason code an error. True if an error code or is not set.
  static bool isError(int code) => code >= 0x80;
}
