/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:event_bus/event_bus.dart' as events;
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {
  MockCH(var clientEventBus, {required int? maxConnectionAttempts});
  @override
  MqttConnectionStatus connectionStatus = MqttConnectionStatus();
}

void main() {
  group('Disconnect on no response', () {
    test('Successful response', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2, 2);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      expect(ka.disconnectTimer?.isActive, isTrue);
      final pingMessageRx = MqttPingResponseMessage();
      ka.pingResponseReceived(pingMessageRx);
      expect(ka.disconnectTimer?.isActive, isFalse);
      expect(disconnect, isFalse);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer?.isActive, isFalse);
    });
    test('No response', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2, 2);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      expect(ka.disconnectTimer?.isActive, isTrue);
      await MqttUtilities.asyncSleep(2);
      expect(disconnect, isTrue);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer?.isActive, isFalse);
    });
  });
  group('Not connected', () {
    test('No ping sent', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.disconnected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      final msg = MqttMessage();
      verifyNever(ch.sendMessage(msg));
      expect(disconnect, isFalse);
      expect(ka.disconnectTimer, isNull);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer, isNull);
    });
  });
}
