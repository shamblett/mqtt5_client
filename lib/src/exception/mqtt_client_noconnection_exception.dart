/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when the client fails to connect
class NoConnectionException implements Exception {
  /// Construct
  NoConnectionException(String message) {
    _message = 'mqtt-client::NoConnectionException: $message';
  }

  String _message;

  @override
  String toString() => _message;
}
