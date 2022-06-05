/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_server_client;

/// The MQTT client server connection base class
class MqttServerConnection extends MqttConnectionBase {
  /// Default constructor
  MqttServerConnection(clientEventBus) : super(clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(server, int port, clientEventBus)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Connect, must be overridden in connection classes
  @override
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Connect for auto reconnect , must be overridden in connection classes
  @override
  Future<void> connectAuto(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log('MqttServerConnection::_startListening');
    try {
      client.listen(_onData, onError: onError, onDone: onDone);
    } on Exception catch (e) {
      print('MqttServerConnection::_startListening - exception raised $e');
    }
  }

  /// OnData listener callback
  void _onData(dynamic data) {
    MqttLogger.log(
        'MqttServerConnection::_onData - Message Received Started <<< ');
    // Protect against 0 bytes but should never happen.
    if (data.isEmpty) {
      MqttLogger.log('MqttServerConnection::_ondata - Error - 0 byte message');
      return;
    }
    MqttLogger.log(
        'MqttServerConnection::_ondata - adding incoming data, data length is ${data.length},'
        ' message stream length is ${messageStream.length}, '
        'message stream position is ${messageStream.position}');
    messageStream.addAll(data);

    while (messageStream.isMessageAvailable()) {
      var messageIsValid = true;
      MqttMessage? msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
        if (msg == null) {
          return;
        }
      } on Exception {
        MqttLogger.log(
            'MqttServerConnection::_ondata - message is not yet valid, '
            'waiting for more data ...');
        messageIsValid = false;
      }
      if (!messageIsValid) {
        messageStream.reset();
        return;
      }
      if (messageIsValid) {
        MqttLogger.log(
            'MqttServerConnection::_onData - MESSAGE RECEIVED -> ', msg);
        // If we have received a valid message we must clear the stream.
        messageStream.shrink();
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(MqttConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MqttMessageAvailable(msg));
          }
          MqttLogger.log(
              'MqttServerConnection::_onData - message available event fired');
        } else {
          MqttLogger.log(
              'MqttServerConnection::_onData - WARN - message available event not fired, event bus is closed');
        }
      }
    }
    MqttLogger.log(
        'MqttServerConnection::_onData - Message Received Ended <<< ');
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }
}
