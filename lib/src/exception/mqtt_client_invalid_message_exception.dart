/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when processing a Message that is invalid in some way.
class InvalidMessageException implements Exception {
  /// Construct
  InvalidMessageException(String text) {
    _message = 'mqtt-client::InvalidMessageException: $text';
  }

  String _message;

  @override
  String toString() => _message;
}
