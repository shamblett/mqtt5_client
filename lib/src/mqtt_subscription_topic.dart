/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// Implementation of a Subscription topic that performs additional validations
/// of topics that are subscribed to.
class MqttSubscriptionTopic extends MqttTopic {
  /// Creates a new instance of a rawTopic from a topic string.
  MqttSubscriptionTopic(String? rawTopic)
      : super(rawTopic, <dynamic>[
          MqttTopic.validateMinLength,
          MqttTopic.validateMaxLength,
          _validateMultiWildcard,
          _validateFragments
        ]);

  /// Validates all unique fragments in the topic match the
  /// MQTT spec requirements.
  static void _validateFragments(MqttTopic topicInstance) {
    // If any fragment contains a wildcard or a multi wildcard
    // but is greater than 1 character long, then it's an error -
    // wildcards must appear by themselves.
    final invalidFragment = topicInstance.topicFragments.any(
        (String fragment) =>
            (fragment.contains(MqttTopic.multiWildcard) ||
                fragment.contains(MqttTopic.wildcard)) &&
            fragment.length > 1);
    if (invalidFragment) {
      throw Exception(
          'mqtt_client::SubscriptionTopic: rawTopic Fragment contains '
          'a wildcard but is more than one character long');
    }
  }

  /// Validates the placement of the multi-wildcard character
  /// in subscription topics.
  static void _validateMultiWildcard(MqttTopic topicInstance) {
    if (topicInstance.rawTopic!.contains(MqttTopic.multiWildcard) &&
        !topicInstance.rawTopic!.endsWith(MqttTopic.multiWildcard)) {
      throw Exception('mqtt_client::SubscriptionTopic: The rawTopic wildcard # '
          'can only be present at the end of a topic');
    }
    if (topicInstance.rawTopic!.length > 1 &&
        topicInstance.rawTopic!.endsWith(MqttTopic.multiWildcard) &&
        !topicInstance.rawTopic!.endsWith(MqttTopic.multiWildcardValidEnd)) {
      throw Exception(
          'mqtt_client::SubscriptionTopic: Topics using the # wildcard '
          'longer than 1 character must '
          'be immediately preceeded by a the rawTopic separator /');
    }
  }

  /// Checks if the rawTopic matches the supplied rawTopic using
  /// the MQTT rawTopic matching rules.
  /// Returns true if the rawTopic matches based on the MQTT rawTopic
  /// matching rules, otherwise false.
  bool matches(MqttPublicationTopic matcheeTopic) {
    // If the left rawTopic is just a multi wildcard then we
    // have a match without
    // needing to check any further.
    if (rawTopic == MqttTopic.multiWildcard) {
      return true;
    }
    // If the topics are an exact match, bail early with a cheap comparison
    if (rawTopic == matcheeTopic.rawTopic) {
      return true;
    }
    // no match yet so we need to check each fragment
    for (var i = 0; i < topicFragments.length; i++) {
      final lhsFragment = topicFragments[i];
      // If we've reached a multi wildcard in the lhs rawTopic,
      // we have a match.
      // (this is the mqtt spec rule finance matches finance or finance/#)
      if (lhsFragment == MqttTopic.multiWildcard) {
        return true;
      }
      final isLhsWildcard = lhsFragment == MqttTopic.wildcard;
      // If we've reached a wildcard match but the matchee does
      // not have anything at this fragment level then it's not a match.
      // (this is the MQTT spec rule 'finance does not match finance/+'
      if (isLhsWildcard && matcheeTopic.topicFragments.length <= i) {
        return false;
      }
      // if lhs is not a wildcard we need to check whether the
      // two fragments match each other.
      if (!isLhsWildcard) {
        final rhsFragment = matcheeTopic.topicFragments[i];
        // If the hs fragment is not wildcard then we need an exact match
        if (lhsFragment != rhsFragment) {
          return false;
        }
      }
      // If we're at the last fragment of the matchee rawTopic but there are
      // more fragments in the lhs rawTopic then the matchee rawTopic
      // is too specific to be a match.
      if (i + 1 == matcheeTopic.topicFragments.length &&
          topicFragments.length > matcheeTopic.topicFragments.length &&
          lhsFragment != matcheeTopic.topicFragments[i]) {
        return false;
      }
      // If we're at the last fragment of the lhs rawTopic but there are
      // more fragments in the matchee then the matchee rawTopic
      // is too specific to be a match.
      if (i + 1 == topicFragments.length &&
          matcheeTopic.topicFragments.length > topicFragments.length) {
        return false;
      }
      // If we're here the current fragment matches so check the next
    }
    // If we exit out of the loop without a return then we have a full match rawTopic/rawTopic which would
    // have been caught by the original exact match check at the top anyway.
    return true;
  }
}
