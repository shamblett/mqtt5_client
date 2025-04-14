/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_browser_client.dart';

/// The MQTT connection class for the browser websocket interface
class MqttBrowserWsConnection extends MqttBrowserConnection {
  /// The websocket subprotocol list
  List<String> protocols = MqttConstants.protocolsSingleDefault;

  /// Default constructor
  MqttBrowserWsConnection(super.eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttBrowserWsConnection.fromConnect(
    String server,
    int port,
    events.EventBus eventBus,
  ) : super(eventBus) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception catch (_, stack) {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS '
          'connection is not valid - $server';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw MqttNoConnectionException(message);
    }
    uri = uri.replace(port: port);

    final uriString = uri.toString();
    MqttLogger.log('MqttBrowserWsConnection::connect -  WS URL is $uriString');
    try {
      // Connect and save the socket.
      client = WebSocket(uriString, protocols.map((e) => e.toJS).toList().toJS);
      wsClient.binaryType = 'arraybuffer';
      StreamSubscription<Event>? openEvents;
      StreamSubscription<CloseEvent>? closeEvents;
      StreamSubscription<Event>? errorEvents;
      openEvents = wsClient.onOpen.listen((e) {
        MqttLogger.log('MqttBrowserWsConnection::connect - websocket is open');
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        _startListening();
        return completer.complete();
      });

      closeEvents = wsClient.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connect - websocket is closed',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttConnectionStatus());
      });
      errorEvents = wsClient.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connect - websocket has errored',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttConnectionStatus());
      });
    } on Exception catch (_, stack) {
      final message =
          'MqttBrowserWsConnection::connect - The connection to the message broker '
          '{$uriString} could not be made.';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    MqttLogger.log('MqttBrowserWsConnection::connect - connection is waiting');
    return completer.future;
  }

  /// Connect auto
  @override
  Future<MqttConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception catch (_, stack) {
      final message =
          'MqttBrowserWsConnection::connectAuto - The URI supplied for the WS '
          'connection is not valid - $server';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttBrowserWsConnection::connectAuto - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw MqttNoConnectionException(message);
    }

    uri = uri.replace(port: port);
    final uriString = uri.toString();
    MqttLogger.log(
      'MqttBrowserWsConnection::connectAuto -  WS URL is $uriString',
    );
    try {
      // Connect and save the socket.
      client = WebSocket(uriString, protocols.map((e) => e.toJS).toList().toJS);
      wsClient.binaryType = 'arraybuffer';
      StreamSubscription<Event>? openEvents;
      StreamSubscription<CloseEvent>? closeEvents;
      StreamSubscription<Event>? errorEvents;
      openEvents = wsClient.onOpen.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket is open',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        _startListening();
        return completer.complete();
      });

      closeEvents = wsClient.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket is closed',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttConnectionStatus());
      });
      errorEvents = wsClient.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket has errored',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttConnectionStatus());
      });
    } on Exception catch (_, stack) {
      final message =
          'MqttBrowserWsConnection::connectAuto - The connection to the message broker '
          '{$uriString} could not be made.';
      Error.throwWithStackTrace(MqttNoConnectionException(message), stack);
    }
    MqttLogger.log(
      'MqttBrowserWsConnection::connectAuto - connection is waiting',
    );
    return completer.future;
  }

  /// Implement stream subscription
  @override
  List<StreamSubscription> onListen() {
    return [
      wsClient.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserConnection::_startListening - websocket is closed',
        );
        onDone();
      }),
      wsClient.onMessage.listen((MessageEvent e) {
        onData(e.data);
      }),
      wsClient.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserConnection::_startListening - websocket has errored',
        );
        onError(e);
      }),
    ];
  }

  /// OnError listener callback
  @override
  void onError(dynamic error) {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
        'MqttConnectionBase::_onError - calling disconnected callback',
      );
      onDisconnected!();
    }
  }

  /// OnDone listener callback
  @override
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
        'MqttConnectionBase::_onDone - calling disconnected callback',
      );
      onDisconnected!();
    }
  }

  @override
  void _disconnect() {
    wsClient.close();
  }
}
