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

  final StreamController<MqttAuthenticateMessage> _authenticated =
      StreamController<MqttAuthenticateMessage>.broadcast();

  /// The stream on which all received authenticate messages are added to
  Stream<MqttAuthenticateMessage> get authenticated => _authenticated.stream;

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
  /// This method will wait indefinitely unless a timeout is specified.
  /// If the re-authenticate times out an authenticate message is returned with the timeout
  /// indicator set.
  Future<MqttAuthenticateMessage> reauthenticate(MqttAuthenticateMessage msg,
      {int waitTimeInSeconds}) {
    send(msg);
    MqttLogger.log(
        'MqttAuthenticationManager::reauthenticate - started, timeout is ${waitTimeInSeconds ?? 'indefinite'}');
    if (waitTimeInSeconds == null) {
      return authenticated.first;
    } else {
      final timeoutMsg = MqttAuthenticateMessage();
      timeoutMsg.timeout = true;
      return authenticated.first.timeout(Duration(seconds: waitTimeInSeconds),
          onTimeout: () => timeoutMsg);
    }
  }

  /// Add the message to the authentication stream.
  void _notifyAuthenticate(MqttAuthenticateMessage message) {
    if (_authenticated.hasListener) {
      _authenticated.add(message);
    }
  }
}
