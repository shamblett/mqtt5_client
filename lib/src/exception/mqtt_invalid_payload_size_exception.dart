/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception that is thrown when the payload of a message
/// is not the correct size.
class MqttInvalidPayloadSizeException implements Exception {
  /// Construct
  MqttInvalidPayloadSizeException(int size, int max) {
    _message = 'mqtt-client::InvalidPayloadSizeException: The size of the '
        'payload ($size bytes) must '
        'be equal to or greater than 0 and less than $max bytes';
  }

  late String _message;

  @override
  String toString() => _message;
}
