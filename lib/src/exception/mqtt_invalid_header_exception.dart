/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when processing a header that is invalid in some way.
class MqttInvalidHeaderException implements Exception {
  /// Construct
  MqttInvalidHeaderException(String text) {
    _message = 'mqtt-client::InvalidHeaderException: $text';
  }

  late String _message;

  @override
  String toString() => _message;
}
