/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// Provides the base implementation of an MQTT topic.
abstract class MqttTopic {
  /// Separator
  static const String topicSeparator = '/';

  /// Multi wildcard
  static const String multiWildcard = '#';

  /// Multi wildcard end
  static const String multiWildcardValidEnd = topicSeparator + multiWildcard;

  /// Wildcard
  static const String wildcard = '+';

  /// Topic length
  static const int maxTopicLength = 65535;

  /// Raw topic
  String? rawTopic;

  /// Topic fragments
  late List<String> topicFragments;

  /// Returns true if there are any wildcards in the specified
  /// rawTopic, otherwise false.
  bool get hasWildcards =>
      rawTopic!.contains(multiWildcard) || rawTopic!.contains(wildcard);

  /// Serves as a hash function for a topics.
  @override
  int get hashCode => rawTopic.hashCode;

  /// Creates a new instance of a rawTopic from a rawTopic string.
  /// rawTopic - The topic to represent.
  /// validations - The validations to run on the rawTopic.
  MqttTopic(this.rawTopic, List<dynamic> validations) {
    topicFragments = rawTopic!.split(topicSeparator[0]);
    // run all validations
    for (final dynamic validation in validations) {
      validation(this);
    }
  }

  /// Validates that the topic does not exceed the maximum length.
  /// topicInstance - The instance to check.
  static void validateMaxLength(MqttTopic topicInstance) {
    if (topicInstance.rawTopic!.length > maxTopicLength) {
      throw Exception(
        'mqtt_client::Topic: The length of the supplied rawTopic '
        '(${topicInstance.rawTopic!.length}) is longer than the '
        'maximum allowable ($maxTopicLength)',
      );
    }
  }

  /// Validates that the topic does not fall below the minimum length.
  /// topicInstance - The instance to check.
  static void validateMinLength(MqttTopic topicInstance) {
    if (topicInstance.rawTopic!.isEmpty) {
      throw Exception(
        'mqtt_client::Topic: rawTopic must contain at least one character',
      );
    }
  }

  /// Checks if one topic equals another topic exactly.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MqttTopic && rawTopic == other.rawTopic;
  }

  /// Returns a String representation of the topic.
  @override
  String toString() => rawTopic!;
}
