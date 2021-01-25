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
MqttEnumHelper<MqttConnectReasonCode?> mqttConnectReasonCode =
    MqttEnumHelper<MqttConnectReasonCode?>(_mqttConnectReasonCodeValues);
