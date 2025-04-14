/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Exception thrown when processing a message that is invalid in some way.
class MqttInvalidMessageException implements Exception {
  late String _message;

  /// Construct
  MqttInvalidMessageException(String text) {
    _message = 'mqtt-client::InvalidMessageException: $text';
  }

  @override
  String toString() => _message;
}

/// Exception thrown when processing a message that is not completely received
class MqttIncompleteMessageException implements Exception {
  late String _message;

  /// Construct
  MqttIncompleteMessageException(String text) {
    _message = 'mqtt-client::IncompleteMessageException: $text';
  }

  @override
  String toString() => _message;
}
