/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Handles the logic and workflow surrounding the authentication processing.
///
/// This class allows authentication message exchange in the gap between sending
/// a connect message with authentication data and receiving a connect acknowledgement
/// message and re-authentication.
class MqttAuthenticationManager {
  MqttAuthenticationManager(this._connectionHandler) {
    _connectionHandler.registerForMessage(
        MqttMessageType.auth, handleAuthentication);
  }

  // The current connection handler.
  final _connectionHandler;

  final _authenticated = StreamController<MqttAuthenticateMessage>.broadcast();

  /// The stream on which all received authenticate messages are added to
  StreamController<MqttAuthenticateMessage> get authenticated => _authenticated;

  /// Handles the receipt of authentication messages from a message broker.
  bool handleAuthentication(MqttMessage msg) {
    final MqttAuthenticateMessage authMsg = msg;
    MqttLogger.log(
        'MqttAuthenticationManager::handleAuthentication - Authentication message received');
    _notifyAuthenticate(authMsg);
    return true;
  }

  /// Send an authenticate message
  void send(MqttAuthenticateMessage msg) {
    _connectionHandler.sendMessage(msg);
    MqttLogger.log(
        'MqttAuthenticationManager::send - Authentication message sent');
  }

  /// Re-authenticate.
  ///
  /// Sends the supplied authentication message and waits for the a response from the broker.
  /// Use this if you wish to re-authenticate without listening for authenticate messages.
  /// This method will wait a default 30 seconds unless another timeout value is specified.
  /// If a timeout value of 0 is supplied the method will wait indefinitely.
  ///
  /// If the re-authenticate times out an authenticate message is returned with the timeout
  /// indicator set.
  Future<MqttAuthenticateMessage> reauthenticate(MqttAuthenticateMessage msg,
      {int waitTimeInSeconds = 30}) async {
    final completer = Completer<MqttAuthenticateMessage>();
    send(msg);
    MqttLogger.log(
        'MqttAuthenticationManager::reauthenticate - started, timeout is ${waitTimeInSeconds ?? 'indefinite'}');
    if (waitTimeInSeconds == 0) {
      await _authenticated.stream.listen((final rxMessage) {
        completer.complete(rxMessage);
      });
    } else {
      final timeoutMsg = MqttAuthenticateMessage();
      timeoutMsg.timeout = true;
      await _authenticated.stream.timeout(Duration(seconds: waitTimeInSeconds),
          onTimeout: (_) {
        completer.complete(timeoutMsg);
      }).listen((final rxMessage) {
        completer.complete(rxMessage);
      });
    }
    return completer.future;
  }

  /// Add the message to the authentication stream.
  void _notifyAuthenticate(MqttAuthenticateMessage message) {
    _authenticated.add(message);
  }
}
