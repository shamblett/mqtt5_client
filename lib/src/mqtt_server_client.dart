/*
 * Package : mqtt_server_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_server_client.dart';

class MqttServerClient extends MqttClient {
  /// Initializes a new instance of the MqttServerClient class using the
  /// default Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  MqttServerClient(
    super.server,
    super.clientIdentifier, {
    this.maxConnectionAttempts = MqttConstants.defaultMaxConnectionAttempts,
  });

  /// Initializes a new instance of the MqttServerClient class using
  /// the supplied Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  /// The port to use
  MqttServerClient.withPort(
    super.server,
    super.clientIdentifier,
    int super.port, {
    this.maxConnectionAttempts = MqttConstants.defaultMaxConnectionAttempts,
  }) : super.withPort();

  /// The security context for secure usage
  SecurityContext securityContext = SecurityContext.defaultContext;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(dynamic certificate)? onBadCertificate;

  /// If set use a websocket connection, otherwise use the default TCP one
  bool useWebSocket = false;

  /// If set use the alternate websocket implementation
  bool useAlternateWebSocketImplementation = false;

  /// If set use a secure connection, note TCP only, do not use for
  /// secure websockets(wss).
  bool secure = false;

  /// Max connection attempts
  final int maxConnectionAttempts;

  /// The client supports the setting of both integer and boolean raw socket options
  /// as supported by the Dart IO library [RawSocketOption](https://api.dart.dev/stable/2.19.3/dart-io/RawSocketOption-class.html) class.
  /// Please consult the documentation for the above class before using this.
  ///
  /// The socket options are set on both the initial connect and auto reconnect.
  ///
  /// The client performs no sanity checking of the values provided, what values are set are
  /// passed on to the socket untouched, as such, care should be used when using this feature,
  /// socket options are usually platform specific and can cause numerous failures at the network
  /// level for the unwary.
  /// Applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// Socket timeout period.
  ///
  /// Specifies the maximum time in milliseconds a connect call will wait for socket connection.
  ///
  /// Can be used to stop excessive waiting time at the network layer.
  /// For TCP sockets only, not websockets.
  ///
  /// Minimum value is 1000ms.
  int? _socketTimeout;
  int? get socketTimeout => _socketTimeout;
  set socketTimeout(int? period) {
    if (period != null && period >= 1000) {
      _socketTimeout = period;
    }
  }

  /// Performs a connect to the message broker with an optional
  /// username and password for the purposes of authentication.
  /// If a username and password are supplied these will override
  /// any previously set in a supplied connection message so if you
  /// supply your own connection message and use the authenticateAs method to
  /// set these parameters do not set them again here.
  @override
  Future<MqttConnectionStatus?> connect(
      [String? username, String? password]) async {
    instantiationCorrect = true;
    clientEventBus = events.EventBus();
    clientEventBus
        ?.on<DisconnectOnNoPingResponse>()
        .listen(disconnectOnNoPingResponse);
    connectionHandler = MqttSynchronousServerConnectionHandler(clientEventBus,
        maxConnectionAttempts: maxConnectionAttempts,
        socketOptions: socketOptions,
        socketTimeout: socketTimeout != null
            ? Duration(milliseconds: socketTimeout!)
            : null);
    if (useWebSocket) {
      connectionHandler.secure = false;
      connectionHandler.useWebSocket = true;
      connectionHandler.useAlternateWebSocketImplementation =
          useAlternateWebSocketImplementation;
      if (websocketProtocolString != null) {
        connectionHandler.websocketProtocols = websocketProtocolString;
      }
    }
    if (secure) {
      connectionHandler.secure = true;
      connectionHandler.useWebSocket = false;
      connectionHandler.useAlternateWebSocketImplementation = false;
      connectionHandler.securityContext = securityContext;
    }
    connectionHandler.onBadCertificate = onBadCertificate;
    return await super.connect(username, password);
  }
}
