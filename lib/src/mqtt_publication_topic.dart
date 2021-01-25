/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of a Publication topic that performs additional validations
/// of messages that are published.
class MqttPublicationTopic extends MqttTopic {
  /// Construction
  MqttPublicationTopic(String? topic)
      : super(topic, <dynamic>[
          MqttTopic.validateMinLength,
          MqttTopic.validateMaxLength,
          _validateWildcards
        ]);

  /// Validates that the topic has no wildcards which are not allowed
  /// in publication topics.
  static void _validateWildcards(MqttTopic topicInstance) {
    if (topicInstance.hasWildcards) {
      throw Exception(
          'mqtt_client::PublicationTopic: Cannot publish to a topic that '
          'contains MQTT topic wildcards (# or +)');
    }
  }
}
