/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// The MQTT server connection class for the websocket interface
class MqttServerWsConnection extends MqttServerConnection {
  /// Callback function to handle bad certificate (self signed).
  /// if true, ignore the error.
  bool Function(X509Certificate certificate)? onBadCertificate;

  /// The websocket subprotocol list
  List<String> protocols = MqttConstants.protocolsMultipleDefault;

  /// Default constructor
  MqttServerWsConnection(
    super.eventBus,
    super.socketOptions,
    super.socketTimeout,
  );

  /// Initializes a new instance of the MqttConnection class.
  MqttServerWsConnection.fromConnect(
    String server,
    int port,
    events.EventBus eventBus,
    List<RawSocketOption> socketOptions,
    Duration? socketTimeout,
  ) : super(eventBus, socketOptions, socketTimeout) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttConnectionStatus?> connect(String server, int port) {
    return _connect(server: server, port: port, auto: false);
  }

  /// Connect Auto
  @override
  Future<MqttConnectionStatus?> connectAuto(String server, int port) {
    return _connect(server: server, port: port, auto: true);
  }

  /// User requested or auto disconnect disconnection
  @override
  void disconnect({bool auto = false}) {
    if (auto) {
      _disconnect();
    } else {
      onDone();
    }
  }

  /// OnDone listener callback
  @override
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
        'MqttWsConnection::_onDone - calling disconnected callback',
      );
      onDisconnected!();
    }
  }

  Future<MqttConnectionStatus?> _connect({
    required String server,
    required int port,
    required bool auto,
  }) {
    final completer = Completer<MqttConnectionStatus?>();
    final ctx = auto ? 'connectAuto' : 'connect';
    MqttLogger.log('MqttWsConnection::$ctx - entered');
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception catch (_, stack) {
      final message =
          'MqttWsConnection::$ctx - The URI supplied for the WS '
          'connection is not valid - $server';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttWsConnection::$ctx - The URI supplied for the WS '
          'has an incorrect scheme - $server';
      throw MqttNoConnectionException(message);
    }
    uri = uri.replace(port: port);
    final uriString = uri.toString();
    MqttLogger.log(
      'MqttWsConnection::$ctx - WS URL is $uriString, protocols are $protocols',
    );
    HttpClient? httpClient;
    if (onBadCertificate != null) {
      httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          return onBadCertificate!(cert);
        };
    }
    try {
      // Connect and save the socket.
      WebSocket.connect(
            uriString,
            protocols: protocols.isNotEmpty ? protocols : null,
            customClient: httpClient,
          )
          .then((dynamic socket) {
            client = socket;
            _startListening();
            completer.complete();
          })
          .catchError((dynamic e) {
            MqttLogger.log(
              'MqttWsConnection::$ctx - WebSocket.connect error $e',
            );
            onError(e);
            completer.completeError(e);
          });
    } on Exception catch (_, stack) {
      final message =
          'MqttWsConnection::$ctx - The connection to the message broker '
          '{$uriString} could not be made.';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    return completer.future;
  }

  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }
}
