/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/11/2026
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// When an established connection dies with a socket error, dart:io reports
/// the error to the socket's stream listener and also completes the socket's
/// done future with it. The listener tears the connection down; done must not
/// reach the zone that called connect as an uncaught error.
///
/// Each test runs a loopback broker that answers CONNECT with a CONNACK, then
/// resets the TCP connection under the client through a small proxy.
void main() {
  // Setting SO_LINGER to 0 before destroy() sends a RST. The option value is
  // platform specific; this one is Linux's.
  const soLingerLinux = 13;
  final skip = Platform.isLinux
      ? false
      : 'Resetting a socket uses the Linux SO_LINGER value';

  Future<List<Object>> connectThenReset({required bool secure}) async {
    final ServerSocket? plain;
    final SecureServerSocket? tls;
    if (secure) {
      final context = SecurityContext()
        ..useCertificateChain(path.join('test', 'pem', 'self_signed.cert'))
        ..usePrivateKey(path.join('test', 'pem', 'self_signed.key'));
      plain = null;
      tls = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
    } else {
      plain = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      tls = null;
    }
    final Stream<Socket> broker = secure ? tls! : plain!;
    final brokerPort = secure ? tls!.port : plain!.port;
    final brokerSockets = <Socket>[];
    broker.listen((socket) {
      brokerSockets.add(socket);
      var acked = false;
      socket.listen((_) {
        if (acked) return;
        acked = true;
        socket.add([0x20, 0x03, 0x00, 0x00, 0x00]); // CONNACK, success
      }, onError: (Object _) {});
      socket.done.ignore();
    });

    // The proxy owns the client-side TCP connection, so it can reset it
    // whatever runs on top.
    final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final toClient = <Socket>[];
    final toBroker = <Socket>[];
    proxy.listen((down) async {
      toClient.add(down);
      final up = await Socket.connect(InternetAddress.loopbackIPv4, brokerPort);
      toBroker.add(up);
      down.listen(up.add, onError: (Object _) {}, onDone: up.destroy);
      up.listen(down.add, onError: (Object _) {}, onDone: down.destroy);
      down.done.ignore();
      up.done.ignore();
    });

    final uncaught = <Object>[];
    final disconnected = Completer<void>();
    final finished = Completer<void>();
    // The body's own failures end the run; only errors that escape to the
    // zone are counted.
    runZonedGuarded(() async {
      try {
        final client =
            MqttServerClient.withPort('127.0.0.1', 'reset-test', proxy.port)
              ..keepAlivePeriod = 30
              ..autoReconnect = false
              ..logging(on: false)
              ..onDisconnected = () {
                if (!disconnected.isCompleted) disconnected.complete();
              };
        if (secure) {
          client
            ..secure = true
            ..onBadCertificate = (Object? _) => true;
        }
        final status = await client.connect();
        expect(status!.state, MqttConnectionState.connected);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        for (final socket in toClient) {
          socket
            ..setRawOption(
              RawSocketOption(
                RawSocketOption.levelSocket,
                soLingerLinux,
                Uint8List.fromList([1, 0, 0, 0, 0, 0, 0, 0]),
              ),
            )
            ..destroy();
        }
        await disconnected.future.timeout(const Duration(seconds: 5));
        // Give a leaked error time to arrive.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        finished.complete();
      } on Object catch (error, stack) {
        finished.completeError(error, stack);
      }
    }, (error, stack) => uncaught.add(error));
    try {
      await finished.future.timeout(const Duration(seconds: 10));
    } finally {
      for (final socket in [...toBroker, ...brokerSockets]) {
        socket.destroy();
      }
      await proxy.close();
      await plain?.close();
      await tls?.close();
    }
    return uncaught;
  }

  test('A reset of a plain connection is not an uncaught error', () async {
    expect(await connectThenReset(secure: false), isEmpty);
  }, skip: skip);

  test('A reset of a secure connection is not an uncaught error', () async {
    expect(await connectThenReset(secure: true), isEmpty);
  }, skip: skip);
}
