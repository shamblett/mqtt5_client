/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// Connection handler that performs server based connections and disconnections
/// to the hostname in a synchronous manner.
class MqttSynchronousServerConnectionHandler
    extends MqttServerConnectionHandler {
  /// Initializes a new instance of the SynchronousMqttConnectionHandler class.
  MqttSynchronousServerConnectionHandler(clientEventBus,
      {required int maxConnectionAttempts, required socketOptions})
      : super(clientEventBus,
            maxConnectionAttempts: maxConnectionAttempts,
            socketOptions: socketOptions) {
    this.clientEventBus = clientEventBus;
    connectTimer = MqttCancellableAsyncSleep(5000);
    initialiseListeners();
  }

  /// Synchronously connect to the specific Mqtt Connection.
  @override
  Future<MqttConnectionStatus> internalConnect(
      String? hostname, int? port, MqttConnectMessage? connectMessage) async {
    var connectionAttempts = 0;
    MqttLogger.log(
        'MqttSynchronousServerConnectionHandler::internalConnect entered');
    authenticationRequested = connectMessage!.authenticationRequested;
    if (authenticationRequested!) {
      MqttLogger.log(
          'MqttSynchronousServerConnectionHandler::internalConnect - authentication requested');
    }
    do {
      // Initiate the connection
      MqttLogger.log(
          'MqttSynchronousServerConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts, auto reconnect in progress $autoReconnectInProgress');
      connectionStatus.state = MqttConnectionState.connecting;
      // Don't reallocate the connection if this is an auto reconnect
      if (!autoReconnectInProgress!) {
        if (useWebSocket) {
          if (useAlternateWebSocketImplementation) {
            MqttLogger.log(
                'MqttSynchronousServerConnectionHandler::internalConnect - '
                'alternate websocket implementation selected');
            connection = MqttServerWs2Connection(
                securityContext, clientEventBus, socketOptions);
          } else {
            MqttLogger.log(
                'MqttSynchronousServerConnectionHandler::internalConnect - '
                'websocket selected');
            connection = MqttServerWsConnection(clientEventBus, socketOptions);
          }
          if (websocketProtocols != null) {
            connection.protocols = websocketProtocols;
          }
        } else if (secure) {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect - '
              'secure selected');
          connection = MqttServerSecureConnection(
              securityContext, clientEventBus, onBadCertificate, socketOptions);
        } else {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect - '
              'insecure TCP selected');
          connection =
              MqttServerNormalConnection(clientEventBus, socketOptions);
        }
        connection.onDisconnected = onDisconnected;
      }

      // Connect
      try {
        if (!autoReconnectInProgress!) {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect - calling connect');
          await connection.connect(hostname, port);
        } else {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect - calling connectAuto');
          await connection.connectAuto(hostname, port);
        }
      } on Exception {
        // Ignore exceptions in an auto reconnect sequence
        if (autoReconnectInProgress!) {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect'
              ' exception thrown during auto reconnect - ignoring');
        } else {
          rethrow;
        }
      }
      MqttLogger.log(
          'MqttSynchronousServerConnectionHandler::internalConnect - '
          'connection complete');
      // Transmit the required connection message to the broker.
      MqttLogger.log('MqttSynchronousServerConnectionHandler::internalConnect '
          'sending connect message');
      sendMessage(connectMessage);
      MqttLogger.log(
          'MqttSynchronousServerConnectionHandler::internalConnect - '
          'pre sleep, state = $connectionStatus');
      // We're the sync connection handler so we need to wait for the
      // brokers acknowledgement of the connection.
      await connectTimer.sleep();
      connectionAttempts++;
      // If we are authenticating we must keep waiting for the connect
      // acknowledgement to indicate the end of the authentication sequence.
      if (authenticationRequested!) {
        do {
          MqttLogger.log(
              'MqttSynchronousServerConnectionHandler::internalConnect - awaiting end of authentication sequence');
          connectTimer = MqttCancellableAsyncSleep(1000);
          await connectTimer.sleep();
        } while (connectionStatus.state != MqttConnectionState.connected);
      }
      MqttLogger.log(
          'MqttSynchronousServerConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
      if (connectionStatus.state != MqttConnectionState.connected) {
        if (!autoReconnectInProgress!) {
          MqttLogger.log(
              'MqttSynchronousMqttServerConnectionHandler::internalConnect failed, attempt $connectionAttempts');
          if (onFailedConnectionAttempt != null) {
            MqttLogger.log(
                'MqttSynchronousMqttServerConnectionHandler::calling onFailedConnectionAttempt');
            onFailedConnectionAttempt!(connectionAttempts);
          }
        }
      }
    } while (connectionStatus.state != MqttConnectionState.connected &&
        connectionAttempts < maxConnectionAttempts!);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      if (!autoReconnectInProgress!) {
        MqttLogger.log(
            'MqttSynchronousServerConnectionHandler::internalConnect failed');
        if (onFailedConnectionAttempt == null) {
          if (connectionStatus.reasonCode == MqttConnectReasonCode.notSet) {
            throw MqttNoConnectionException(
                'The maximum allowed connection attempts '
                '({$maxConnectionAttempts}) were exceeded. '
                'The broker is not responding to the connection request message '
                '(Missing Connection Acknowledgement?');
          } else {
            throw MqttNoConnectionException(
                'The maximum allowed connection attempts '
                '({$maxConnectionAttempts}) were exceeded. '
                'The broker is not responding to the connection request message correctly '
                'The reason code is ${connectionStatus.reasonCode}');
          }
        } else {
          connectionStatus.state = MqttConnectionState.faulted;
        }
      }
    }
    MqttLogger.log('MqttSynchronousServerConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    initialConnectionComplete = true;
    return connectionStatus;
  }
}
