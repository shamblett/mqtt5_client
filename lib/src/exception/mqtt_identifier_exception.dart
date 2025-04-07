/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Exception thrown when a client identifier included in a message is too long.
class MqttIdentifierException implements Exception {
  late String _message;

  /// Construct
  MqttIdentifierException(String clientIdentifier) {
    _message =
        'mqtt-client::ClientIdentifierException: Client id $clientIdentifier '
        'is too long at ${clientIdentifier.length}, '
        'Maximum ClientIdentifier length is '
        '${MqttConstants.maxClientIdentifierLength}';
  }

  @override
  String toString() => _message;
}
