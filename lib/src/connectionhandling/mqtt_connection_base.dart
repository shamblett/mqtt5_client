/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt5_client.dart';

/// The MQTT client connection base class
abstract class MqttConnectionBase<T extends Object> {
  /// The socket that maintains the connection to the MQTT broker.
  @protected
  T? client;

  /// The stream controller as returned when clients listen.
  @protected
  List<StreamSubscription> listeners = [];

  /// The read wrapper
  @protected
  MqttReadWrapper readWrapper = MqttReadWrapper();

  ///The read buffer
  @protected
  MqttByteBuffer messageStream = MqttByteBuffer(typed.Uint8Buffer());

  /// Unsolicited disconnection callback
  @internal
  DisconnectCallback? onDisconnected;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// Default constructor
  MqttConnectionBase(this.clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttConnectionBase.fromConnect(String server, int port, this.clientEventBus) {
    connect(server, port);
  }

  /// Stops listening on the socket immediately, must be overridden in connection classes
  void stopListening();

  /// Closes the socket immediately, must be overridden in connection classes
  void closeClient();

  /// Closes and dispose the socket immediately, must be overridden in connection classes
  @mustCallSuper
  void disposeClient();

  /// Connect for auto reconnect.
  @protected
  @mustBeOverridden
  Future<void> connectAuto(String server, int port) {
    MqttLogger.log(
      'MqttConnectionBase::connectAuto - Server $server, port $port',
    );
    final completer = Completer<void>();
    return completer.future;
  }

  /// Connect.
  @protected
  @mustBeOverridden
  Future<void> connect(String server, int port) {
    MqttLogger.log('MqttConnectionBase::connect - Server $server, port $port');
    final completer = Completer<void>();
    return completer.future;
  }

  /// OnError listener callback
  @protected
  void onError(dynamic error) {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
        'MqttConnectionBase::_onError - calling disconnected callback, error is $error',
      );
      onDisconnected!();
    }
  }

  /// OnDone listener callback
  @protected
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
        'MqttConnectionBase::_onDone - calling disconnected callback',
      );
      onDisconnected!();
    }
  }

  /// User requested or auto disconnect disconnection
  @protected
  void disconnect({bool auto = false}) {
    if (auto) {
      _disconnect();
    } else {
      onDone();
    }
  }

  /// Internal disconnect with stop listeners and dispose client
  void _disconnect() {
    stopListening();
    disposeClient();
  }
}
