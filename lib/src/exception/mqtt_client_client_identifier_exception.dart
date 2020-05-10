/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when a client identifier included in a message is too long.
class ClientIdentifierException implements Exception {
  /// Construct
  ClientIdentifierException(String clientIdentifier) {
    _message =
        'mqtt-client::ClientIdentifierException: Client id $clientIdentifier '
        'is too long at ${clientIdentifier.length}, '
        'Maximum ClientIdentifier length is '
        '${MqttClientConstants.maxClientIdentifierLength}';
  }

  String _message;

  @override
  String toString() => _message;
}
