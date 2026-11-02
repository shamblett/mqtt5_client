/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// The MQTT client server connection base class
abstract class MqttServerConnection<T extends Object>
    extends MqttConnectionBase<T> {
  /// Socket timeout OS error codes.
  static const wsaETimedOut = 10060;
  static const eTimedOut = 110;

  /// Socket options, applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// Socket timeout duration.
  Duration? socketTimeout;

  /// If set, the server name is resolved and each of its addresses is tried
  /// in random order, moving on to the next when the connection, or for a
  /// secure connection the TLS handshake, fails. TCP connections only.
  bool randomizeServerAddresses = false;

  /// Default constructor
  MqttServerConnection(
    super.clientEventBus,
    this.socketOptions,
    this.socketTimeout,
  );

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(
    server,
    int port,
    clientEventBus,
    this.socketOptions,
    this.socketTimeout,
  ) : super(clientEventBus) {
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

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final length = message.length;
    final messageBytes = message.read(length);
    _sendToClient(messageBytes.toList());
  }

  /// Runs [attempt] against [server], or with [randomizeServerAddresses]
  /// against each of its addresses in random order until one succeeds.
  ///
  /// A broker name with several addresses is usually there to spread clients
  /// across brokers, but the platform resolver typically returns the same
  /// order every time, and a TLS handshake failure is not retried on the
  /// next address, so every client ends up on the first one, including when
  /// it is the one that is failing. An address from a lookup keeps the name
  /// it was looked up by, so a secure connection still verifies the
  /// certificate against the server name.
  Future<S> _connectToServer<S>(
    String server,
    Future<S> Function(Object host) attempt,
  ) async {
    if (!randomizeServerAddresses || InternetAddress.tryParse(server) != null) {
      return attempt(server);
    }
    final addresses = await InternetAddress.lookup(server);
    addresses.shuffle();
    Object? lastError;
    StackTrace? lastStack;
    for (final address in addresses) {
      try {
        return await attempt(address);
      } catch (e, stack) {
        MqttLogger.log(
          'MqttServerConnection::_connectToServer - ${address.address} '
          'failed, $e',
        );
        lastError = e;
        lastStack = stack;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStack!);
  }

  /// Write data to the client. Must be implemented by subclasses.
  void _sendToClient(List<int> data);

  // Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log('MqttServerConnection::_startListening');
    try {
      _listenToClient(_onData, onError, onDone);
    } on Exception catch (e) {
      print('MqttServerConnection::_startListening - exception raised $e');
    }
  }

  /// Subscribe to the client. Must be implemented by subclasses.
  void _listenToClient(
    void Function(dynamic) onData,
    void Function(dynamic) onError,
    void Function() onDone,
  );

  // OnData listener callback
  void _onData(dynamic data) {
    MqttLogger.log(
      'MqttServerConnection::_onData - Message Received Started <<< ',
    );
    // Protect against 0 bytes but should never happen.
    if (data.isEmpty) {
      MqttLogger.log('MqttServerConnection::_ondata - Error - 0 byte message');
      return;
    }
    MqttLogger.log(
      'MqttServerConnection::_ondata - adding incoming data, data length is ${data.length},'
      ' message stream length is ${messageStream.length}, '
      'message stream position is ${messageStream.position}',
    );
    messageStream.addAll(data);
    MqttLogger.log(
      'MqttServerConnection::_ondata - added incoming data'
      ' message stream length is ${messageStream.length}, '
      'message stream position is ${messageStream.position}',
    );

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
            'waiting for more data ...',
          );
          messageIsValid = false;
        } catch (e) {
          MqttLogger.log(
            'MqttServerConnection::_ondata - exception raised is $e',
          );
          rethrow;
        }
        if (!messageIsValid) {
          messageStream.shrink();
          return;
        }
        if (messageIsValid) {
          MqttLogger.log(
            'MqttServerConnection::_onData - MESSAGE RECEIVED -> ',
            msg,
          );
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
                'MqttServerConnection::_onData - message available event fired',
              );
            } else {
              MqttLogger.log(
                'MqttServerConnection::_onData - message not processed, event bus is closed',
              );
            }
          } else {
            MqttLogger.log(
              'MqttServerConnection::_onData - message not processed, event bus is null',
            );
          }
        }
      }
    } catch (e) {
      MqttLogger.log(
        'MqttServerConnection::_ondata - irrecoverable exception raised - sending disconnect $e',
      );
      // Send disconnect
      final disconnect = MqttDisconnectMessage()
        ..withReasonCode(MqttDisconnectReasonCode.normalDisconnection);
      messageStream.seek(0);
      messageStream.clear();
      disconnect.writeTo(messageStream);
      messageStream.seek(0);
      send(messageStream);
    }
    MqttLogger.log(
      'MqttServerConnection::_onData - Message Received Ended <<< ',
    );
  }

  // Apply any socket options, true indicates options applied
  bool _applySocketOptions(Socket socket, List<RawSocketOption> socketOptions) {
    if (socketOptions.isNotEmpty) {
      MqttLogger.log(
        'MqttServerConnection::__applySocketOptions - Socket options supplied, applying',
      );
      for (final option in socketOptions) {
        socket.setRawOption(option);
      }
    }
    return socketOptions.isNotEmpty;
  }

  // Check for a timeout exception
  bool _isSocketTimeout(Exception e) {
    if (e is SocketException) {
      // There are different timeout codes for Linux and Windows so check for both
      if (e.osError?.errorCode == wsaETimedOut ||
          e.osError?.errorCode == eTimedOut) {
        return true;
      }
    }
    return false;
  }
}
