/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Exception thrown when the client fails to connect
class MqttNoConnectionException implements Exception {
  late String _message;

  /// Construct
  MqttNoConnectionException(String message) {
    _message = 'mqtt-client::NoConnectionException: $message';
  }

  @override
  String toString() => _message;
}
