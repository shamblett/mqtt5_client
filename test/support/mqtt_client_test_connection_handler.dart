/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

class TestConnectionHandlerNoSend extends MqttServerConnectionHandler {
  TestConnectionHandlerNoSend(var clientEventBus,
      {int? maxConnectionAttempts, socketOptions})
      : super(clientEventBus,
            maxConnectionAttempts: maxConnectionAttempts,
            socketOptions: socketOptions);

  @override
  Future<MqttConnectionStatus> internalConnect(
      String? hostname, int? port, MqttConnectMessage? message) {
    final completer = Completer<MqttConnectionStatus>();
    return completer.future;
  }

  /// Alternate websocket implementation.
  ///
  /// The Amazon Web Services (AWS) IOT MQTT interface(and maybe others)
  /// has a bug that causes it not to connect if unexpected message headers are
  /// present in the initial GET message during the handshake.
  /// Since the httpclient classes insist on adding those headers, an alternate
  /// method is used to perform the handshake.
  /// After the handshake everything goes back to the normal websocket class.
  /// Only use this websocket implementation if you know it is needed
  /// by your broker.
}

class TestConnectionHandlerSend extends MqttServerConnectionHandler {
  TestConnectionHandlerSend(var clientEventBus,
      {int? maxConnectionAttempts, socketOptions})
      : super(clientEventBus,
            maxConnectionAttempts: maxConnectionAttempts,
            socketOptions: socketOptions);

  /// Alternate websocket implementation.
  ///
  /// The Amazon Web Services (AWS) IOT MQTT interface(and maybe others)
  /// has a bug that causes it not to connect if unexpected message headers are
  /// present in the initial GET message during the handshake.
  /// Since the httpclient classes insist on adding those headers, an alternate
  /// method is used to perform the handshake.
  /// After the handshake everything goes back to the normal websocket class.
  /// Only use this websocket implementation if you know it is needed
  /// by your broker.

  /// If set use a secure connection, note TCP only, not websocket.
  ///
  /// Callback function to handle bad certificate. if true, ignore the error.

  List<MqttMessage> sentMessages = <MqttMessage>[];

  @override
  Future<MqttConnectionStatus> internalConnect(
      String? hostname, int? port, MqttConnectMessage? message) {
    final completer = Completer<MqttConnectionStatus>();
    return completer.future;
  }

  @override
  MqttConnectionState disconnect() =>
      connectionStatus.state = MqttConnectionState.disconnected;

  @override
  void sendMessage(MqttMessage message) {
    sentMessages.add(message);
  }
}
