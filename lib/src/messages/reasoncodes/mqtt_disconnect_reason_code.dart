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

/// Disconnect processing reason codes.
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
MqttEnumHelper<MqttDisconnectReasonCode?> mqttDisconnectReasonCode =
    MqttEnumHelper<MqttDisconnectReasonCode?>(_mqttDisconnectReasonCodeValues);
