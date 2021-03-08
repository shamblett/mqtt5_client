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
MqttEnumHelper<MqttPublishReasonCode?> mqttPublishReasonCode =
    MqttEnumHelper<MqttPublishReasonCode?>(_mqttPublishReasonCodeValues);
