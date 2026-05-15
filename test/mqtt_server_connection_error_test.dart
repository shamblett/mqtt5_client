/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_buffers.dart';
import 'support/mqtt_client_mock_socket.dart';

class MqttMockSocketMalformedInbound extends MockSocket {
  dynamic onDataFunc;
  final writes = <List<int>>[];
  bool initial = true;

  static MqttMockSocketMalformedInbound? instance;

  static Future<MqttMockSocketMalformedInbound> connect(
    host,
    int port, {
    sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) {
    final completer = Completer<MqttMockSocketMalformedInbound>();
    final extSocket = MqttMockSocketMalformedInbound();
    extSocket.port = port;
    extSocket.host = host;
    instance = extSocket;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    writes.add(List<int>.from(data));
    mockBytes.addAll(data);
    if (initial) {
      initial = false;
      _sendConnectAck();
    }
  }

  void emitMalformedConnectAck() {
    onDataFunc(Uint8List.fromList([0x20, 0x03, 0x00, 0x00, 0xFF]));
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onDataFunc = onData;
    return outgoing;
  }

  void _sendConnectAck() {
    final ack = MqttConnectAckMessage()
      ..withReasonCode(MqttConnectReasonCode.success);
    final buff = Uint8Buffer();
    final ms = MqttByteBuffer(buff);
    ack.writeTo(ms);
    ms.seek(0);
    onDataFunc(Uint8List.fromList(ms.buffer!.toList()));
  }
}

void main() {
  test('Malformed inbound message sends a clean disconnect frame', () async {
    await IOOverrides.runZoned(
      () async {
        final client = MqttServerClient(
          'localhost',
          'MqttMalformedInboundTest',
          maxConnectionAttempts: 1,
        );
        client.connectionMessage = MqttConnectMessage().withClientIdentifier(
          'MqttMalformedInboundTest',
        );

        final status = await client.connect();
        expect(status?.state, MqttConnectionState.connected);

        final socket = MqttMockSocketMalformedInbound.instance!;
        socket.writes.clear();
        socket.emitMalformedConnectAck();

        expect(socket.writes.last, [0xE0, 0x00]);
      },
      socketConnect:
          (
            dynamic host,
            int port, {
            dynamic sourceAddress,
            int sourcePort = 0,
            Duration? timeout,
          }) => MqttMockSocketMalformedInbound.connect(
            host,
            port,
            sourceAddress: sourceAddress,
            sourcePort: sourcePort,
            timeout: timeout,
          ),
    );
  });
}
