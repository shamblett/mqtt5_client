/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// Callback function definitions
typedef MessageCallbackFunction = bool Function(MqttMessage message);

/// The connection handler interface class
abstract class MqttIConnectionHandler {
  /// The connection status
  MqttConnectionStatus get connectionStatus;

  /// Successful connection callback
  ConnectCallback? onConnected;

  /// Unsolicited disconnection callback
  DisconnectCallback? onDisconnected;

  /// Auto reconnect callback
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Failed connection attempt callback
  FailedConnectionAttemptCallback? onFailedConnectionAttempt;

  /// Auto reconnect in progress
  bool? autoReconnectInProgress;

  // Server name, needed for auto reconnect.
  String? server;

  // Port number, needed for auto reconnect.
  int? port;

  // Connection message, needed for auto reconnect.
  MqttConnectMessage? connectionMessage;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(dynamic certificate)? onBadCertificate;

  /// Runs the disconnection process to stop communicating
  /// with a message broker.
  MqttConnectionState disconnect([MqttDisconnectMessage disconnectMessage]);

  /// Indicates if the connect message has an authentication method
  /// i.e. authentication has been requested.
  bool? authenticationRequested;

  /// Closes a connection.
  void close();

  /// Connects to a message broker
  /// The broker server to connect to
  /// The port to connect to
  /// The connect message to use to initiate the connection
  Future<MqttConnectionStatus> connect(
      String server, int port, MqttConnectMessage message);

  /// Register the specified callback to receive messages of a specific type.
  /// The type of message that the callback should be sent
  /// The callback function that will accept the message type
  void registerForMessage(
      MqttMessageType msgType, MessageCallbackFunction msgProcessorCallback);

  ///  Sends a message to a message broker.
  void sendMessage(MqttMessage message);

  /// Unregisters the specified callbacks so it not longer receives
  /// messages of the specified type.
  /// The message type the callback currently receives
  void unRegisterForMessage(MqttMessageType msgType);

  /// Registers a callback to be executed whenever a message is
  /// sent by the connection handler.
  void registerForAllSentMessages(MessageCallbackFunction sentMsgCallback);

  /// UnRegisters a callback that is registerd to be executed whenever a
  /// message is sent by the connection handler.
  void unRegisterForAllSentMessages(MessageCallbackFunction sentMsgCallback);
}
