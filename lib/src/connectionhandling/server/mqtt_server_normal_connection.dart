/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_server_client;

/// The MQTT normal(insecure TCP) server connection class
class MqttServerNormalConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerNormalConnection(events.EventBus? eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerNormalConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connect- entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((dynamic socket) {
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        onError(e);
        completer.completeError(e);
      });
    } on Exception catch (e) {
      completer.completeError(e);
      final message = 'MqttNormalConnection::The connection to the message '
          'broker {$server}:{$port} could not be made.';
      throw MqttNoConnectionException(message);
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
      Socket.connect(server, port).then((dynamic socket) {
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        onError(e);
        completer.completeError(e);
      });
    } on Exception catch (e) {
      completer.completeError(e);
      final message =
          'MqttNormalConnection::ConnectAuto - The connection to the message '
          'broker {$server}:{$port} could not be made.';
      throw MqttNoConnectionException(message);
    }
    return completer.future;
  }
}
