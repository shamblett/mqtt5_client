/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'support/mqtt_client_mockbroker.dart';

void main() {
  // Test wide variables
  final broker = MockBroker();
  const mockBrokerAddress = 'localhost';
  const testClientId = 'SJHMQTTClient';

  test(
    'Connected - Broker Disconnects Stays Inactive',
    () async {
      var autoReconnectCallbackCalled = false;
      var disconnectCallbackCalled = false;
      var connectionFailedCallbackCalled = false;

      void messageHandlerConnect(typed.Uint8Buffer? messageArrived) {
        final ack = MqttConnectAckMessage();
        broker.sendMessage(ack);
      }

      void autoReconnect() {
        autoReconnectCallbackCalled = true;
      }

      void disconnect() {
        disconnectCallbackCalled = true;
      }

      void connectionFailed(int attempt) {
        connectionFailedCallbackCalled = true;
      }

      broker.setMessageHandler = messageHandlerConnect;
      await broker.start();
      final client = MqttServerClient(mockBrokerAddress, testClientId);
      client.logging(on: true);
      client.autoReconnect = true;
      client.onAutoReconnect = autoReconnect;
      client.onDisconnected = disconnect;
      client.onFailedConnectionAttempt = connectionFailed;
      const username = 'unused 4';
      print(username);
      const password = 'password 4';
      print(password);
      await client.connect();
      expect(
        client.connectionStatus!.state == MqttConnectionState.connected,
        isTrue,
      );
      await MqttUtilities.asyncSleep(2);
      await broker.stop();
      await MqttUtilities.asyncSleep(60);
      expect(autoReconnectCallbackCalled, isTrue);
      expect(disconnectCallbackCalled, isFalse);
      expect(connectionFailedCallbackCalled, isFalse);
      expect(
        client.connectionStatus!.state == MqttConnectionState.connecting,
        isTrue,
      );
      broker.close();
    },
    timeout: Timeout(Duration(seconds: 80)),
  );
}
