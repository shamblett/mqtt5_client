/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_browser_client;

/// Connection handler that performs connections and disconnections
/// to the hostname in a synchronous manner.
class MqttSynchronousBrowserConnectionHandler
    extends MqttBrowserConnectionHandler {
  /// Initializes a new instance of the MqttConnectionHandler class.
  MqttSynchronousBrowserConnectionHandler(
    clientEventBus, {
    required int maxConnectionAttempts,
  }) : super(clientEventBus, maxConnectionAttempts: maxConnectionAttempts) {
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
        'MqttSynchronousMqttBrowserConnectionHandler::internalConnect entered');
    do {
      // Initiate the connection
      MqttLogger.log(
          'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts, auto reconnect in progress $autoReconnectInProgress');
      connectionStatus.state = MqttConnectionState.connecting;
      // Don't reallocate the connection if this is an auto reconnect
      if (!autoReconnectInProgress!) {
        connection = MqttBrowserWsConnection(clientEventBus);
        if (websocketProtocols != null) {
          connection.protocols = websocketProtocols;
        }
        connection.onDisconnected = onDisconnected;
      }
      // Connect
      try {
        if (!autoReconnectInProgress!) {
          MqttLogger.log(
              'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - calling connect');
          await connection.connect(hostname, port);
        } else {
          MqttLogger.log(
              'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - calling connectAuto');
          await connection.connectAuto(hostname, port);
        }
      } on Exception {
        // Ignore exceptions in an auto reconnect sequence
        if (autoReconnectInProgress!) {
          MqttLogger.log(
              'MqttSynchronousMqttBrowserConnectionHandler::internalConnect'
              ' exception thrown during auto reconnect - ignoring');
        } else {
          rethrow;
        }
      }
      MqttLogger.log(
          'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - '
          'connection complete');
      // Transmit the required connection message to the broker.
      MqttLogger.log(
          'MqttSynchronousMqttBrowserConnectionHandler::internalConnect '
          'sending connect message');
      sendMessage(connectMessage!);
      MqttLogger.log(
          'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - '
          'pre sleep, state = $connectionStatus');
      // We're the sync connection handler so we need to wait for the
      // brokers acknowledgement of the connections
      await connectTimer.sleep();
      MqttLogger.log(
          'MqttSynchronousMqttBrowserConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
    } while (connectionStatus.state != MqttConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts!);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      if (!autoReconnectInProgress!) {
        MqttLogger.log(
            'MqttSynchronousMqttBrowserConnectionHandler::internalConnect failed');
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
              'The reason code is ${mqttConnectReasonCode.asString(connectionStatus.reasonCode)}');
        }
      }
    }
    MqttLogger.log(
        'MqttSynchronousMqttBrowserConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    initialConnectionComplete = true;
    return connectionStatus;
  }
}
