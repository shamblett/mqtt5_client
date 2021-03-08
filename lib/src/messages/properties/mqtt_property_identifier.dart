/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// MQTT property identifier
enum MqttPropertyIdentifier {
  /// Payload Format Indicator - Byte
  payloadFormatIndicator,

  /// Message Expiry Interval - Four Byte Integer
  messageExpiryInterval,

  /// Content Type - UTF-8 Encoded String
  contentType,

  /// Response Topic - UTF-8 Encoded String
  responseTopic,

  /// Correlation Data - Binary Data
  correlationdata,

  /// Subscription Identifier - Variable Byte Integer
  subscriptionIdentifier,

  /// Session Expiry Interval - Four Byte Integer
  sessionExpiryInterval,

  /// Assigned client Identifier - UTF-8 Encoded String
  assignedClientIdentifier,

  /// broker Keep Alive - Two Byte Integer
  serverKeepAlive,

  /// Authentication Method - UTF-8 Encoded String
  authenticationMethod,

  /// Authentication Data - Binary Data
  authenticationData,

  /// Request Problem Information - Byte
  requestProblemInformation,

  /// Will Delay Interval - Four Byte Integer
  willDelayInterval,

  /// Request Response Information - Byte
  requestResponseInformation,

  /// Response Information - UTF-8 Encoded String
  responseInformation,

  /// broker Reference - UTF-8 Encoded String
  serverReference,

  /// Reason String - UTF-8 Encoded String
  reasonString,

  /// Receive Maximum - Two Byte Integer
  receiveMaximum,

  /// Topic Alias Maximum - Two Byte Integer
  topicAliasMaximum,

  /// Topic Alias - Two Byte Integer
  topicAlias,

  /// Maximum QoS - Byte
  maximumQos,

  /// Retain Available - Byte
  retainAvailable,

  /// User Property - UTF-8 String Pair
  userProperty,

  /// Maximum Packet Size - Four Byte Integer
  maximumPacketSize,

  /// Wildcard Subscription Available - Byte
  wildcardSubscriptionAvailable,

  /// Subscription Identifier Available - Byte
  subscriptionIdentifierAvailable,

  /// Shared Subscription Available - Byte
  sharedSubscriptionAvailable,

  /// Not set indicator
  notSet
}

/// MQTT property identifier support
const Map<int, MqttPropertyIdentifier> _mqttPropertyIdentifierValues =
    <int, MqttPropertyIdentifier>{
  0x01: MqttPropertyIdentifier.payloadFormatIndicator,
  0x02: MqttPropertyIdentifier.messageExpiryInterval,
  0x03: MqttPropertyIdentifier.contentType,
  0x08: MqttPropertyIdentifier.responseTopic,
  0x09: MqttPropertyIdentifier.correlationdata,
  0x0b: MqttPropertyIdentifier.subscriptionIdentifier,
  0x11: MqttPropertyIdentifier.sessionExpiryInterval,
  0x12: MqttPropertyIdentifier.assignedClientIdentifier,
  0x13: MqttPropertyIdentifier.serverKeepAlive,
  0x15: MqttPropertyIdentifier.authenticationMethod,
  0x16: MqttPropertyIdentifier.authenticationData,
  0x17: MqttPropertyIdentifier.requestProblemInformation,
  0x18: MqttPropertyIdentifier.willDelayInterval,
  0x19: MqttPropertyIdentifier.requestResponseInformation,
  0x1a: MqttPropertyIdentifier.responseInformation,
  0x1c: MqttPropertyIdentifier.serverReference,
  0x1f: MqttPropertyIdentifier.reasonString,
  0x21: MqttPropertyIdentifier.receiveMaximum,
  0x22: MqttPropertyIdentifier.topicAliasMaximum,
  0x23: MqttPropertyIdentifier.topicAlias,
  0x24: MqttPropertyIdentifier.maximumQos,
  0x25: MqttPropertyIdentifier.retainAvailable,
  0x26: MqttPropertyIdentifier.userProperty,
  0x27: MqttPropertyIdentifier.maximumPacketSize,
  0x28: MqttPropertyIdentifier.wildcardSubscriptionAvailable,
  0x29: MqttPropertyIdentifier.subscriptionIdentifierAvailable,
  0x2a: MqttPropertyIdentifier.sharedSubscriptionAvailable,
  0xff: MqttPropertyIdentifier.notSet
};

/// MQTT property identifier helper
MqttEnumHelper<MqttPropertyIdentifier?> mqttPropertyIdentifier =
    MqttEnumHelper<MqttPropertyIdentifier?>(_mqttPropertyIdentifierValues);
