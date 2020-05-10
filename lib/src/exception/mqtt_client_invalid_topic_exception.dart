/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when the topic of a message is invalid
class InvalidTopicException implements Exception {
  /// Construct
  InvalidTopicException(String message, String topic) {
    _message = 'mqtt-client::InvalidTopicException: Topic $topic is $message';
  }

  String _message;

  @override
  String toString() => _message;
}
