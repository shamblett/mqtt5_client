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
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';

// ignore_for_file: invalid_use_of_protected_member
void main() {
  // Test wide variables
  final brokerWs = MockBrokerWs();
  const mockBrokerAddressWs = 'ws://localhost/ws';
  const mockBrokerAddressWsNoScheme = 'localhost.com';
  const mockBrokerAddressWsBad = '://localhost.com';
  const mockBrokerPortWs = 8090;
  const testClientId = 'syncMqttTests';
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  group('Connection parameters', () {
    test('Invalid URL', () async {
      try {
        final clientEventBus = events.EventBus();
        final ch = MqttSynchronousServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.useWebSocket = true;
        await ch.connect(
          mockBrokerAddressWsBad,
          mockBrokerPortWs,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
      } on Exception catch (e) {
        expect(e is MqttNoConnectionException, true);
        expect(
          e.toString(),
          'mqtt-client::NoConnectionException: '
          'MqttWsConnection::The URI supplied for the WS connection is not valid - ://localhost.com',
        );
      }
    });

    test('Web Protocol string', () {
      var protocols = MqttConstants.protocolsMultipleDefault;
      expect(protocols.join(' ').trim(), 'mqtt mqttv3.1 mqttv3.11');
      protocols = MqttConstants.protocolsSingleDefault;
      expect(protocols.join(' ').trim(), 'mqtt');
      protocols = <String>[];
      expect(protocols.join(' ').trim(), '');
    });

    test('Invalid URL - bad scheme', () async {
      try {
        final clientEventBus = events.EventBus();
        final ch = MqttSynchronousServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.useWebSocket = true;
        await ch.connect(
          mockBrokerAddressWsNoScheme,
          mockBrokerPortWs,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
      } on Exception catch (e) {
        expect(e is MqttNoConnectionException, true);
        expect(
          e.toString(),
          'mqtt-client::NoConnectionException: '
          'MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme',
        );
      }
    });
  });

  group('Connection Keep Alive - Mock broker WS', () {
    test('Successful response WS', () async {
      var expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer? messageArrived) {
        final ack = MqttConnectAckMessage();
        brokerWs.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer? messageArrived) {
        final headerStream = MqttByteBuffer(messageArrived);
        final header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
            'WS Connection Keep Alive - Successful response - Ping Request received $expectRequest',
          );
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await brokerWs.start();
      final clientEventBus = events.EventBus();
      final ch = MqttSynchronousServerConnectionHandler(
        clientEventBus,
        maxConnectionAttempts: 3,
        socketOptions: socketOptions,
        socketTimeout: null,
      );
      MqttLogger.loggingOn = true;
      ch.useWebSocket = true;
      ch.websocketProtocols = <String>['SJHprotocol'];
      brokerWs.setMessageHandler = messageHandlerConnect;
      await ch.connect(
        mockBrokerAddressWs,
        mockBrokerPortWs,
        MqttConnectMessage().withClientIdentifier(testClientId),
      );
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      brokerWs.setMessageHandler = messageHandlerPingRequest;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      print(
        'WS Connection Keep Alive - Successful response - keepealive ms is ${ka.keepAlivePeriod}',
      );
      print(
        'WS Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer!.isActive.toString()}',
      );
      final stopwatch = Stopwatch()..start();
      await MqttUtilities.asyncSleep(10);
      print(
        'WS Connection Keep Alive - Successful response - Elapsed time '
        'is ${stopwatch.elapsedMilliseconds / 1000} seconds',
      );
      ka.stop();
      ch.close();
    });
  });
}
