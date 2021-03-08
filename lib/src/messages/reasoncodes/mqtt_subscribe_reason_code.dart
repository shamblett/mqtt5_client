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
  wildcardSubscriptionsNotSupported,

  /// Not set indicator, not part of the MQTT specification
  notSet
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
  0xa2: MqttSubscribeReasonCode.wildcardSubscriptionsNotSupported,
  0xff: MqttSubscribeReasonCode.notSet
};

/// MQTT subscribe reason code helper
MqttEnumHelper<MqttSubscribeReasonCode?> mqttSubscribeReasonCode =
    MqttEnumHelper<MqttSubscribeReasonCode?>(_mqttSubscribeReasonCodeValues);
