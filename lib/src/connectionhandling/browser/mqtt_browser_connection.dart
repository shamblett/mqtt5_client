/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_browser_client;

/// The MQTT browser connection base class
class MqttBrowserConnection extends MqttConnectionBase {
  /// Default constructor
  MqttBrowserConnection(clientEventBus) : super(clientEventBus);

  /// Initializes a new instance of the MqttBrowserConnection class.
  MqttBrowserConnection.fromConnect(server, port, clientEventBus)
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
    MqttLogger.log('MqttBrowserConnection::_startListening');
    try {
      client.onClose.listen((e) {
        MqttLogger.log(
            'MqttBrowserConnection::_startListening - websocket is closed');
        onDone();
      });
      client.onMessage.listen((MessageEvent e) {
        _onData(e.data);
      });
      client.onError.listen((e) {
        MqttLogger.log(
            'MqttBrowserConnection::_startListening - websocket has errored');
        onError(e);
      });
    } on Exception catch (e) {
      MqttLogger.log(
          'MqttBrowserConnection::_startListening - exception raised $e');
    }
  }

  /// OnData listener callback
  void _onData(dynamic byteData) {
    MqttLogger.log(
        'MqttBrowserConnection::_onData - Message Received Started <<< ');
    // Protect against 0 bytes but should never happen.
    var data = Uint8List.view(byteData);
    if (data.isEmpty) {
      MqttLogger.log('MqttBrowserConnection::_ondata - Error - 0 byte message');
      return;
    }

    MqttLogger.log(
        'MqttBrowserConnection::_ondata - adding incoming data, data length is ${data.length}, '
        'message stream length is ${messageStream.length}, '
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
            'MqttBrowserConnection::_ondata - message is not yet valid, '
            'waiting for more data ...');
        messageIsValid = false;
      }
      if (!messageIsValid) {
        messageStream.reset();
        return;
      }
      if (messageIsValid) {
        MqttLogger.log(
            'MqttBrowserConnection::_onData - MESSAGE RECEIVED -> ', msg);
        // If we have received a valid message we must shrink the stream
        messageStream.shrink();
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(MqttConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MqttMessageAvailable(msg));
          }
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message available event fired');
        } else {
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message not processed, disconnecting');
        }
      }
    }
    MqttLogger.log(
        'MqttBrowserConnection::_onData - Message Received Ended <<< ');
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    var buffer = messageBytes.buffer;
    var bData = ByteData.view(buffer);
    client?.sendTypedData(bData);
  }

  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }

  /// OnDone listener callback
  @override
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttBrowserConnection::_onDone - calling disconnected callback');
      onDisconnected!();
    }
  }
}
