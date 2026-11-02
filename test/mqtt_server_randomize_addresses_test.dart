/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2026
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart' as events;
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// 'localhost' resolves to both 127.0.0.1 and ::1. A good TLS broker listens
/// on ::1 only and something that accepts TCP but fails the handshake on
/// 127.0.0.1, on the same port: with randomizeServerAddresses the client must
/// always end up on ::1, whichever address it tries first.
void main() {
  late Directory certs;
  late SecureServerSocket good;
  late ServerSocket bad;
  late int port;

  SecurityContext clientContext() =>
      SecurityContext()
        ..setTrustedCertificates(path.join(certs.path, 'ca.cert'));

  setUpAll(() async {
    final addresses = await InternetAddress.lookup('localhost');
    if (!addresses.any((a) => a.type == InternetAddressType.IPv4) ||
        !addresses.any((a) => a.type == InternetAddressType.IPv6)) {
      markTestSkipped('localhost does not resolve to both IPv4 and IPv6');
      return;
    }
    // Made fresh each run rather than kept in test/pem: macOS only accepts a
    // TLS server certificate with serverAuth, a subjectAltName and a short
    // lifetime, so a checked-in one would stop working.
    certs = await Directory.systemTemp.createTemp('mqtt5_client_test');
    Future<void> openssl(List<String> args) async {
      final r = await Process.run(
        'openssl',
        args,
        workingDirectory: certs.path,
      );
      if (r.exitCode != 0) {
        throw StateError('openssl ${args.first}: ${r.stderr}');
      }
    }

    try {
      await openssl([
        'req', '-x509', '-newkey', 'rsa:2048', '-nodes', //
        '-keyout', 'ca.key', '-out', 'ca.cert', '-days', '2',
        '-subj', '/CN=mqtt5_client test CA',
        '-addext', 'basicConstraints=critical,CA:TRUE',
        '-addext', 'keyUsage=critical,keyCertSign',
      ]);
      await openssl([
        'req', '-newkey', 'rsa:2048', '-nodes', //
        '-keyout', 'leaf.key', '-out', 'leaf.csr', '-subj', '/CN=localhost',
      ]);
      await File(path.join(certs.path, 'leaf.ext')).writeAsString(
        'subjectAltName=DNS:localhost\n'
        'extendedKeyUsage=serverAuth\n'
        'keyUsage=critical,digitalSignature,keyEncipherment\n'
        'basicConstraints=CA:FALSE\n',
      );
      await openssl([
        'x509', '-req', '-in', 'leaf.csr', '-CA', 'ca.cert', //
        '-CAkey', 'ca.key', '-CAcreateserial', '-out', 'leaf.cert',
        '-days', '2', '-extfile', 'leaf.ext',
      ]);
    } on Object catch (e) {
      markTestSkipped('could not make test certificates: $e');
      return;
    }
    final serverContext = SecurityContext()
      ..useCertificateChain(path.join(certs.path, 'leaf.cert'))
      ..usePrivateKey(path.join(certs.path, 'leaf.key'));
    good = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv6,
      0,
      serverContext,
      v6Only: true,
    );
    port = good.port;
    // Handshakes the client abandons (see the certificate test) fail here.
    good.listen((s) => s.listen((_) {}, onError: (_) {}), onError: (_) {});
    bad = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    bad.listen((s) => s.destroy());
  });

  tearDownAll(() async {
    await good.close();
    await bad.close();
    await certs.delete(recursive: true);
  });

  Future<SecureSocket?> connect(
    String server, {
    required bool randomize,
  }) async {
    final conn = MqttServerSecureConnection(
      clientContext(),
      events.EventBus(),
      null,
      <RawSocketOption>[],
      null,
    )..randomizeServerAddresses = randomize;
    try {
      await conn.connect(server, port);
    } on Object {
      return null;
    }
    // ignore: invalid_use_of_protected_member
    return conn.client;
  }

  test('every connection gets past the failing address', () async {
    for (var i = 0; i < 10; i++) {
      final socket = await connect('localhost', randomize: true);
      expect(socket, isNotNull, reason: 'attempt $i');
      expect(socket!.remoteAddress.type, InternetAddressType.IPv6);
      socket.destroy();
    }
  });

  test('the certificate is still checked against the server name', () async {
    // The same broker by address: its certificate is for localhost, not ::1.
    expect(await connect('::1', randomize: true), isNull);
  });

  test('without it, a handshake failure is not retried', () async {
    // The platform orders the addresses; whenever 127.0.0.1 comes first
    // the connection fails outright. Only meaningful in that case.
    final first = (await InternetAddress.lookup('localhost')).first;
    if (first.type != InternetAddressType.IPv4) {
      markTestSkipped('this platform tries ::1 first');
      return;
    }
    expect(await connect('localhost', randomize: false), isNull);
  });
}
