/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 24/01/2020
 * Copyright :  S.Hamblett
 */

@TestOn('browser')
library;

import 'dart:async';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_browser_client.dart';
import 'package:test/test.dart';

void main() {
  const mosquittoServer = 'ws://test.mosquitto.org';
  const mosquittoPort = 8080;
  const testClientId = 'syncMqttTests';

  // Runs in the VM: a fake MQTT5 broker over websocket. It answers every
  // CONNECT with a CONNACK (success), and drops the first connection after
  // 500 ms, like a broker restart.
  const brokerCode = r'''
import 'dart:io';
import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel channel) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  var connections = 0;
  server.listen((req) async {
    final ws = await WebSocketTransformer.upgrade(req,
        protocolSelector: (protocols) => protocols.first);
    final n = ++connections;
    var acked = false;
    ws.listen((data) {
      if (!acked) {
        acked = true;
        ws.add([0x20, 0x03, 0x00, 0x00, 0x00]); // CONNACK, success
        channel.sink.add('connack $n');
        if (n == 1) {
          Future.delayed(const Duration(milliseconds: 500), () {
            channel.sink.add('closing $n');
            ws.close();
          });
        }
      }
    });
  });
  channel.sink.add(server.port);
}
''';
  group('Broker tests', () {
    test('Connect mosquitto test broker', () async {
      var pongCount = 0;
      void connectCallback() {
        print('Browser client connected callback');
      }

      void pongCallback() {
        print('Browser client pong callback');
        pongCount++;
      }

      final sleeper = MqttCancellableAsyncSleep(25000);
      final client = MqttBrowserClient(mosquittoServer, testClientId);
      client.port = mosquittoPort;
      client.logging(on: true);
      client.onConnected = connectCallback;
      client.pongCallback = pongCallback;
      client.keepAlivePeriod = 10;
      client.websocketProtocols = MqttConstants.protocolsSingleDefault;
      final connMess = MqttConnectMessage()
          .withClientIdentifier(testClientId)
          .startClean(); // Non persistent session for testing
      client.connectionMessage = connMess;
      var ok = true;
      try {
        await client.connect();
        var connectionOK = false;
        if (client.connectionStatus!.state == MqttConnectionState.connected) {
          print('Browser client connected locally');
          connectionOK = true;
        } else {
          print(
            'Browser client connection failed - disconnecting, status is ${client.connectionStatus}',
          );
          client.disconnect();
        }
        await sleeper.sleep();
        if (connectionOK) {
          if (pongCount == 2) {
            print('Browser client disconnecting normally');
            client.disconnect();
          }
        }
      } on MqttNoConnectionException {
        print(
          '>>>>> TEST NOT OK - No connection exception thrown, cannot connect to Mosquitto',
        );
        ok = false;
      }
      expect(ok, isTrue);
    }, timeout: Timeout.factor(2));
  });

  group('Connection close tests', () {
    test('auto-reconnects after the broker closes the websocket', () async {
      final broker = spawnHybridCode(brokerCode);
      final events = StreamIterator(broker.stream);
      expect(await events.moveNext(), isTrue);
      final port = events.current as int;

      final client = MqttBrowserClient('ws://127.0.0.1', 'close-test')
        ..port = port
        ..keepAlivePeriod = 60
        ..autoReconnect = true
        ..logging(on: false);
      final reconnected = Completer<void>();
      var disconnectedCalls = 0;
      client.onAutoReconnected = () {
        if (!reconnected.isCompleted) reconnected.complete();
      };
      client.onDisconnected = () => disconnectedCalls++;

      final status = await client.connect();
      expect(status?.state, MqttConnectionState.connected);

      // The broker drops the socket; the client must notice and reconnect.
      await reconnected.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => fail(
          'onAutoReconnected never fired '
          '(state: ${client.connectionStatus?.state})',
        ),
      );
      expect(client.connectionStatus?.state, MqttConnectionState.connected);
      expect(disconnectedCalls, 0);

      client.autoReconnect = false;
      client.disconnect();
    });
  });
}
