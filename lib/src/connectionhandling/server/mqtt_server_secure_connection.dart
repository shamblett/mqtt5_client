/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_server_client.dart';

/// The MQTT server secure connection class
class MqttServerSecureConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerSecureConnection(
      this.context,
      events.EventBus? eventBus,
      this.onBadCertificate,
      List<RawSocketOption> socketOptions,
      Duration? socketTimeout)
      : super(eventBus, socketOptions, socketTimeout);

  /// Initializes a new instance of the MqttServerSecureConnection class.
  MqttServerSecureConnection.fromConnect(
      String server,
      int port,
      events.EventBus eventBus,
      List<RawSocketOption> socketOptions,
      Duration? socketTimeout)
      : super(eventBus, socketOptions, socketTimeout) {
    connect(server, port);
  }

  /// The security context for secure usage
  SecurityContext? context;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate)? onBadCertificate;

  /// Connect
  @override
  Future<MqttConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    MqttLogger.log('MqttServerSecureConnection::connect - entered');
    try {
      SecureSocket.connect(server, port,
              onBadCertificate: onBadCertificate,
              context: context,
              timeout: socketTimeout)
          .then((SecureSocket socket) {
        MqttLogger.log('MqttServerSecureConnection::connect - securing socket');
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttServerSecureConnection::connect - socket options applied');
        }
        client = socket;
        MqttLogger.log('MqttServerSecureConnection::connect - start listening');
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        if (_isSocketTimeout(e)) {
          final message =
              'MqttNormalConnection::connect - The connection to the message broker '
              '{$server}:{$port} could not be made, a socket timeout has occurred';
          MqttLogger.log(message);
          completer.complete();
        } else {
          onError(e);
          completer.completeError(e);
        }
      });
    } on SocketException catch (e) {
      final message =
          'MqttServerSecureConnection::The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw MqttNoConnectionException(message);
    } on HandshakeException catch (e) {
      final message =
          'MqttServerSecureConnection::Handshake exception to the message broker '
          '{$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw MqttNoConnectionException(message);
    } on TlsException catch (e) {
      final message =
          'MqttServerSecureConnection::TLS exception raised on secure '
          'connection. Error is ${e.toString()}';
      throw MqttNoConnectionException(message);
    }
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttConnectionStatus?>();
    MqttLogger.log('MqttServerSecureConnection::connectAuto - entered');
    try {
      SecureSocket.connect(server, port,
              onBadCertificate: onBadCertificate, context: context)
          .then((SecureSocket socket) {
        MqttLogger.log(
            'MqttServerSecureConnection::connectAuto - securing socket');
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttServerSecureConnection::connectAuto - socket options applied');
        }
        client = socket;
        MqttLogger.log(
            'MqttServerSecureConnection::connectAuto - start listening');
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        if (_isSocketTimeout(e)) {
          final message =
              'MqttNormalConnection::connectAuto - The connection to the message broker '
              '{$server}:{$port} could not be made, a socket timeout has occurred';
          MqttLogger.log(message);
          completer.complete();
        } else {
          onError(e);
          completer.completeError(e);
        }
      });
    } on SocketException catch (e) {
      final message =
          'MqttServerSecureConnection::connectAuto - The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw MqttNoConnectionException(message);
    } on HandshakeException catch (e) {
      final message =
          'MqttServerSecureConnection::connectAuto - Handshake exception to the message broker '
          '{$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw MqttNoConnectionException(message);
    } on TlsException catch (e) {
      final message =
          'MqttServerSecureConnection::connectAuto - TLS exception raised on secure '
          'connection. Error is ${e.toString()}';
      throw MqttNoConnectionException(message);
    }
    return completer.future;
  }
}
