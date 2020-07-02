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
    await authManager.authenticated.stream.listen((final rxmessage) {
      expect(rxmessage.authenticationMethod, 'Auth method');
    });
    authManager.handleAuthentication(message);
  }, timeout: Timeout.factor(0.1));

  test('Reauthenticate - No timeout', () async {
    final authManager = MqttAuthenticationManager(testCHS);
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    authManager.authenticated.stream.listen((event) { print('Listener');});
    authManager.handleAuthentication(message);
    print('Outer');
    final rxmessage =
        await authManager.reauthenticate(message, waitTimeInSeconds: 1);
    print('Inner');
    expect(rxmessage.authenticationMethod, 'Auth method');
    expect(rxmessage.timeout, isFalse);
    authManager.handleAuthentication(message);
  }, timeout: Timeout.factor(0.1));
}
