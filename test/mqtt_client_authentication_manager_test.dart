/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'support/mqtt_client_test_connection_handler.dart';

@TestOn('vm')

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {}

class MockCON extends Mock implements MqttServerNormalConnection {}

final TestConnectionHandlerSend testCHS = TestConnectionHandlerSend();

void main() {
  test('On Authentication Message Received', () async {
    final authManager = MqttAuthenticationManager(testCHS);
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    await authManager.authenticated.stream.listen((final rxMessage) {
      expect(rxMessage.authenticationMethod, 'Auth method');
      expect(rxMessage.timeout, isFalse);
    });
    authManager.handleAuthentication(message);
  }, timeout: Timeout.factor(0.1));

  test('Reauthenticate - Timeout No Message', () async {
    final authManager = MqttAuthenticationManager(testCHS);
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    final rxmessage =
        await authManager.reauthenticate(message, waitTimeInSeconds: 5);
    expect(rxmessage.timeout, isTrue);
    expect(rxmessage.authenticationMethod, isNull);
  }, timeout: Timeout.factor(0.5));

  test('Reauthenticate - Timeout With Message', () async {
    final authManager = MqttAuthenticationManager(testCHS);
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    final rxmessage =
        await authManager.reauthenticate(message, waitTimeInSeconds: 0);
    authManager.handleAuthentication(message);
    expect(rxmessage.timeout, isTrue);
    expect(rxmessage.authenticationMethod, isNull);
  }, timeout: Timeout.factor(0.1));
}
