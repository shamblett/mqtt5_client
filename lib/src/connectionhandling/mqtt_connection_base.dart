/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The MQTT client connection base class
class MqttConnectionBase {
  /// Default constructor
  MqttConnectionBase(this.clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttConnectionBase.fromConnect(String server, int port, this.clientEventBus) {
    connect(server, port);
  }

  /// The socket that maintains the connection to the MQTT broker.
  @protected
  dynamic client;

  /// The read wrapper
  @protected
  MqttReadWrapper readWrapper = MqttReadWrapper();

  ///The read buffer
  @protected
  MqttByteBuffer messageStream = MqttByteBuffer(typed.Uint8Buffer());

  /// Unsolicited disconnection callback
  @protected
  DisconnectCallback? onDisconnected;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// Connect for auto reconnect , must be overridden in connection classes
  @protected
  Future<void> connectAuto(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Connect, must be overridden in connection classes
  @protected
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// OnError listener callback
  @protected
  void onError(dynamic error) {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttConnectionBase::_onError - calling disconnected callback');
      onDisconnected!();
    }
  }

  /// OnDone listener callback
  @protected
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttConnectionBase::_onDone - calling disconnected callback');
      onDisconnected!();
    }
  }

  void _disconnect() {
    // On disconnect clean(discard) anything in the message stream
    messageStream.clean();
    if (client != null) {
      client.destroy();
      client = null;
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
}
