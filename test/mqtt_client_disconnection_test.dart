/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_buffers.dart';
import 'support/mqtt_client_mock_socket.dart';

void main() {
  test('Disconnect Normal Disconnect', () async {
    await IOOverrides.runZoned(
      () async {
        bool connectionFailed = false;
        bool onDisconnectedCalled = false;
        void onDisconnected() {
          onDisconnectedCalled = true;
        }

        final client = MqttServerClient(
          'localhost',
          '',
          maxConnectionAttempts: 1,
        );
        client.connectionMessage = MqttConnectMessage().withClientIdentifier(
          'MqttDisconnectTest',
        );
        client.onDisconnected = onDisconnected;
        try {
          await client.connect();
        } on Exception catch (e) {
          expect(e is MqttNoConnectionException, isTrue);
          connectionFailed = true;
        }
        expect(connectionFailed, isFalse);
        expect(client.connectionStatus?.state, MqttConnectionState.connected);
        expect(
          client.connectionStatus?.reasonCode,
          MqttConnectReasonCode.success,
        );
        client.publishMessage(
          'PublishTest',
          MqttQos.atLeastOnce,
          Uint8Buffer(),
        );
        await Future.delayed(Duration(seconds: 1));
        expect(
          client.connectionStatus?.state,
          MqttConnectionState.disconnected,
        );
        expect(
          client.connectionStatus?.disconnectMessage.reasonCode,
          MqttDisconnectReasonCode.normalDisconnection,
        );
        expect(
          client.connectionStatus?.disconnectionOrigin,
          MqttDisconnectionOrigin.brokerSolicited,
        );
        expect(onDisconnectedCalled, isTrue);
      },
      socketConnect:
          (
            dynamic host,
            int port, {
            dynamic sourceAddress,
            int sourcePort = 0,
            Duration? timeout,
          }) => MqttMockSocketDisconnectNormal.connect(
            host,
            port,
            sourceAddress: sourceAddress,
            sourcePort: sourcePort,
            timeout: timeout,
          ),
    );
  });

  test('Disconnect Session Take Over', () async {
    await IOOverrides.runZoned(
      () async {
        bool connectionFailed = false;
        bool onDisconnectedCalled = false;
        void onDisconnected() {
          onDisconnectedCalled = true;
        }

        final client = MqttServerClient(
          'localhost',
          '',
          maxConnectionAttempts: 1,
        );
        client.connectionMessage = MqttConnectMessage().withClientIdentifier(
          'MqttDisconnectTest',
        );
        client.onDisconnected = onDisconnected;
        try {
          await client.connect();
        } on Exception catch (e) {
          expect(e is MqttNoConnectionException, isTrue);
          connectionFailed = true;
        }
        expect(connectionFailed, isFalse);
        expect(client.connectionStatus?.state, MqttConnectionState.connected);
        expect(
          client.connectionStatus?.reasonCode,
          MqttConnectReasonCode.success,
        );
        client.publishMessage(
          'PublishTest',
          MqttQos.atLeastOnce,
          Uint8Buffer(),
        );
        await Future.delayed(Duration(seconds: 1));
        expect(
          client.connectionStatus?.state,
          MqttConnectionState.disconnected,
        );
        expect(
          client.connectionStatus?.disconnectMessage.reasonCode,
          MqttDisconnectReasonCode.sessionTakenOver,
        );
        expect(
          client.connectionStatus?.disconnectionOrigin,
          MqttDisconnectionOrigin.brokerSolicited,
        );
        expect(onDisconnectedCalled, isTrue);
      },
      socketConnect:
          (
            dynamic host,
            int port, {
            dynamic sourceAddress,
            int sourcePort = 0,
            Duration? timeout,
          }) => MqttMockSocketDisconnectSessionTakeOver.connect(
            host,
            port,
            sourceAddress: sourceAddress,
            sourcePort: sourcePort,
            timeout: timeout,
          ),
    );
  });
}
