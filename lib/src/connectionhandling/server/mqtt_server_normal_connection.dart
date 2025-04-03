/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// The MQTT normal(insecure TCP) server connection class
class MqttServerNormalConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerNormalConnection(
    super.eventBus,
    super.socketOptions,
    super.socketTimeout,
  );

  /// Initializes a new instance of the MqttConnection class.
  MqttServerNormalConnection.fromConnect(
    String server,
    int port,
    events.EventBus eventBus,
    List<RawSocketOption> socketOptions,
    Duration? socketTimeout,
  ) : super(eventBus, socketOptions, socketTimeout) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connect- entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port, timeout: socketTimeout)
          .then((dynamic socket) {
            // Socket options
            final applied = _applySocketOptions(socket, socketOptions);
            if (applied) {
              MqttLogger.log(
                'MqttNormalConnection::connect - socket options applied',
              );
            }
            client = socket;
            _startListening();
            completer.complete();
          })
          .catchError((dynamic e) {
            if (_isSocketTimeout(e)) {
              final message =
                  'MqttNormalConnection::connect - The connection to the message broker '
                  '{$server}:{$port} could not be made, a socket timeout has occurred';
              MqttLogger.log(message);
              completer.complete();
            } else {
              onError(e);
              completer.completeError(e);
            }
          });
    } on Exception catch (e, stack) {
      completer.completeError(e);
      final message =
          'MqttNormalConnection::The connection to the message '
          'broker {$server}:{$port} could not be made.';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connectAuto - entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port)
          .then((dynamic socket) {
            // Socket options
            final applied = _applySocketOptions(socket, socketOptions);
            if (applied) {
              MqttLogger.log(
                'MqttNormalConnection::connectAuto - socket options applied',
              );
            }
            client = socket;
            _startListening();
            completer.complete();
          })
          .catchError((dynamic e) {
            if (_isSocketTimeout(e)) {
              final message =
                  'MqttNormalConnection::connectAuto - The connection to the message broker '
                  '{$server}:{$port} could not be made, a socket timeout has occurred';
              MqttLogger.log(message);
              completer.complete();
            } else {
              onError(e);
              completer.completeError(e);
            }
          });
    } on Exception catch (e, stack) {
      completer.completeError(e);
      final message =
          'MqttNormalConnection::ConnectAuto - The connection to the message '
          'broker {$server}:{$port} could not be made.';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    return completer.future;
  }
}
