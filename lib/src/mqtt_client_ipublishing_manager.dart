/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Interface that defines how the publishing manager publishes
/// messages to the broker and how it passed on messages that are
/// received from the broker.
abstract class IPublishingManager {
  /// Publish a message to the broker on the specified topic.
  /// Returns the message identifier assigned to the message.
  int publish(MqttPublicationTopic topic, MqttQos qualityOfService,
      typed.Uint8Buffer data,
      {bool retain = false, List<MqttStringPairProperty> userProperties});

  /// Publish a user supplied publish message
  int publishUserMessage(MqttPublishMessage message);

  /// The message received event
  MessageReceived publishEvent;
}
