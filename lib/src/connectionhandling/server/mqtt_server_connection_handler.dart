/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

///  This class provides specific connection functionality
///  for server based connections.
abstract class MqttServerConnectionHandler extends MqttConnectionHandlerBase {
  /// Use a websocket rather than TCP
  bool useWebSocket = false;

  /// Socket timeout duration.
  Duration? socketTimeout;

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
  bool useAlternateWebSocketImplementation = false;

  /// If set use a secure connection, note TCP only, not websocket.
  bool secure = false;

  /// The security context for secure usage
  dynamic securityContext;

  /// Socket options
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// Initializes a new instance of the [MqttServerConnectionHandler] class.
  MqttServerConnectionHandler(
    super.clientEventBus, {
    required super.maxConnectionAttempts,
    required this.socketOptions,
    required this.socketTimeout,
  });
}
