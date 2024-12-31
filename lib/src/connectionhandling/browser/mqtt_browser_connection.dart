/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_browser_client.dart';

/// The MQTT browser connection base class
abstract class MqttBrowserConnection extends MqttConnectionBase {
  /// Default constructor
  MqttBrowserConnection(super.clientEventBus);

  /// Initializes a new instance of the MqttBrowserConnection class.
  MqttBrowserConnection.fromConnect(server, port, clientEventBus)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// The socket that maintains the connection to the MQTT broker.
  /// Get and set methods preserve type information.
  WebSocket get wsClient => (client as WebSocket);
  set(WebSocket ws) => client = ws;

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
      onListen();
    } on Exception catch (e) {
      MqttLogger.log(
          'MqttBrowserConnection::_startListening - exception raised $e');
    }
  }

  /// Implement stream subscription
  List<StreamSubscription> onListen();

  /// OnData listener callback
  void onData(dynamic byteData) {
    MqttLogger.log(
        'MqttBrowserConnection::_onData - Message Received Started <<< ');

    // Normally the byteData is a ByteBuffer,
    // but for SKWasm / WASM, the byteData is a JSArrayBuffer,
    // so we need to convert it to a Dart ByteBuffer
    // before we convert it to a Uint8List.
    // ignore: invalid_runtime_check_with_js_interop_types
    if (byteData is JSArrayBuffer) {
      byteData = byteData.toDart;
    }
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
        if (clientEventBus != null) {
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
                'MqttBrowserConnection::_onData - message not processed, event bus is closed');
          }
        } else {
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message not processed, event bus is null');
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
    wsClient.send(bData.jsify()!);
  }

  void _disconnect() {
    wsClient.close();
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
