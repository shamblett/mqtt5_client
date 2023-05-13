/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when processing a message that is invalid in some way.
class MqttInvalidMessageException implements Exception {
  /// Construct
  MqttInvalidMessageException(String text) {
    _message = 'mqtt-client::InvalidMessageException: $text';
  }

  late String _message;

  @override
  String toString() => _message;
}

/// Exception thrown when processing a message that is not completely received
class MqttIncompleteMessageException implements Exception {
  /// Construct
  MqttIncompleteMessageException(String text) {
    _message = 'mqtt-client::IncompleteMessageException: $text';
  }

  late String _message;

  @override
  String toString() => _message;
}
