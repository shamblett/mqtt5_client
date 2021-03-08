/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Exception thrown when the connection state is incorrect.
class MqttConnectionException implements Exception {
  /// Construct
  MqttConnectionException(MqttConnectionState? state) {
    _message = 'mqtt-client::ConnectionException: The connection must be in '
        'the Connected state in order to perform this operation.';
    if (null != state) {
      _message = '$_message Current state is ${state.toString().split('.')[1]}';
    }
  }

  late String _message;

  @override
  String toString() => _message;
}
