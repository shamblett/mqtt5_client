/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Exception thrown when a browser or server client is instantiated incorrectly.
class MqttIncorrectInstantiationException implements Exception {
  late String _message;

  /// Construct
  MqttIncorrectInstantiationException() {
    _message =
        'mqtt-client::ClientIncorrectInstantiationException: Incorrect instantiation, do not'
        'instantiate MqttClient directly, use MqttServerClient or MqttBrowserClient';
  }

  @override
  String toString() => _message;
}
