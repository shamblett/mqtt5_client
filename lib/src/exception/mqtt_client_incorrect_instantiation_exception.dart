/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when a browser or server client is instantiated incorrectly.
class IncorrectInstantiationException implements Exception {
  /// Construct
  IncorrectInstantiationException() {
    _message =
        'mqtt-client::ClientIncorrectInstantiationException: Incorrect instantiation, do not'
        'instantiate MqttClient directly, use MqttServerClient or MqttBrowserClient';
  }

  String _message;

  @override
  String toString() => _message;
}
