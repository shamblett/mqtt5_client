/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// The MQTT client server connection base class
class MqttServerConnection extends MqttConnectionBase {
  /// Default constructor
  MqttServerConnection(super.clientEventBus, this.socketOptions);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(
      server, int port, clientEventBus, this.socketOptions)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Socket options, applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

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
    MqttLogger.log('MqttServerConnection::_ondata - added incoming data'
        ' message stream length is ${messageStream.length}, '
        'message stream position is ${messageStream.position}');

    // Catch all unexpected exceptions, if any send a disconnect message
    try {
      while (messageStream.isMessageAvailable()) {
        var messageIsValid = true;
        MqttMessage? msg;

        try {
          msg = MqttMessage.createFrom(messageStream);
          if (msg == null) {
            return;
          }
        } on MqttIncompleteMessageException {
          MqttLogger.log(
              'MqttServerConnection::_ondata - message is not yet valid, '
              'waiting for more data ...');
          messageIsValid = false;
        } catch (e) {
          MqttLogger.log(
              'MqttServerConnection::_ondata - exception raised is $e');
          rethrow;
        }
        if (!messageIsValid) {
          messageStream.shrink();
          return;
        }
        if (messageIsValid) {
          MqttLogger.log(
              'MqttServerConnection::_onData - MESSAGE RECEIVED -> ', msg);
          // If we have received a valid message we must shrink the stream
          messageStream.shrink();
          if (!clientEventBus!.streamController.isClosed) {
            if (msg!.header!.messageType == MqttMessageType.connectAck) {
              clientEventBus!.fire(MqttConnectAckMessageAvailable(msg));
            } else {
              clientEventBus!.fire(MqttMessageAvailable(msg));
            }
            MqttLogger.log(
                'MqttServerConnection::_onData - message available event fired');
          }
        }
      }
    } catch (e) {
      MqttLogger.log(
          'MqttServerConnection::_ondata - irrecoverable exception raised - sending disconnect $e');
      // Send disconnect
      final disconnect = MqttDisconnectMessage()
        ..withReasonCode(MqttDisconnectReasonCode.normalDisconnection);
      messageStream.reset();
      disconnect.writeTo(messageStream);
      messageStream.seek(0);
      send(messageStream);
    }
    MqttLogger.log(
        'MqttServerConnection::_onData - Message Received Ended <<< ');
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }

  // Apply any socket options, true indicates options applied
  bool _applySocketOptions(Socket socket, List<RawSocketOption> socketOptions) {
    if (socketOptions.isNotEmpty) {
      MqttLogger.log(
          'MqttServerConnection::__applySocketOptions - Socket options supplied, applying');
      for (final option in socketOptions) {
        socket.setRawOption(option);
      }
    }
    return socketOptions.isNotEmpty;
  }
}
