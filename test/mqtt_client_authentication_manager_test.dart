/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart' as events;
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';
import 'support/mqtt_client_test_connection_handler.dart';

void main() {
  List<RawSocketOption> socketOptions = <RawSocketOption>[];
  test('On Authentication Message Received', () async {
    final authManager = MqttAuthenticationManager();
    final clientEventBus = events.EventBus();
    final testCHS =
        TestConnectionHandlerSend(clientEventBus, socketOptions: socketOptions);
    authManager.connectionHandler = testCHS;
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    authManager.authenticated.stream.listen((final rxMessage) {
      expect(rxMessage.authenticationMethod, 'Auth method');
      expect(rxMessage.timeout, isFalse);
    });
    authManager.handleAuthentication(message);
  }, timeout: Timeout.factor(0.1));

  test('Reauthenticate - Timeout No Message', () async {
    final authManager = MqttAuthenticationManager();
    final clientEventBus = events.EventBus();
    final testCHS =
        TestConnectionHandlerSend(clientEventBus, socketOptions: socketOptions);
    authManager.connectionHandler = testCHS;
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    final rxmessage =
        await authManager.reauthenticate(message, waitTimeInSeconds: 2);
    expect(rxmessage.timeout, isTrue);
    expect(rxmessage.authenticationMethod, isNull);
  }, timeout: Timeout.factor(0.1));

  test('Reauthenticate - Timeout With Message', () async {
    final clientEventBus = events.EventBus();
    final testCHS =
        TestConnectionHandlerSend(clientEventBus, socketOptions: socketOptions);
    final authManager = MqttAuthenticationManager();
    authManager.connectionHandler = testCHS;
    final message = MqttAuthenticateMessage()
        .withAuthenticationMethod('Auth method')
        .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);
    expect(message.isValid, isTrue);
    Timer(
        Duration(seconds: 1), () => authManager.handleAuthentication(message));
    final rxmessage =
        await authManager.reauthenticate(message, waitTimeInSeconds: 2);
    authManager.handleAuthentication(message);
    expect(rxmessage.timeout, isFalse);
    expect(rxmessage.authenticationMethod, 'Auth method');
    expect(testCHS.sentMessages.length, 1);
    expect(testCHS.sentMessages[0].header!.messageType, MqttMessageType.auth);
    final bm = testCHS.sentMessages[0] as MqttAuthenticateMessage;
    expect(bm.authenticationMethod, 'Auth method');
    expect(bm.timeout, isFalse);
    expect(bm.isValid, isTrue);
  }, timeout: Timeout.factor(0.1));
}
