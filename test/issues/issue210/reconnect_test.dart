@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:mqtt5_client/mqtt5_browser_client.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

// Runs in the VM: starts a real Mosquitto with a websocket listener. On 'drop'
// it kills Mosquitto with SIGKILL (the connection ends without a websocket
// close frame, like a broker crash or reboot) and restarts it 2 s later on the
// same port. Set MOSQUITTO to the binary if it is not on PATH.
const _brokerCode = r'''
import 'dart:async';
import 'dart:io';
import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel channel) async {
  Future<int> freePort() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    return port;
  }

  final port = await freePort();
  final mqttPort = await freePort();
  final dir = await Directory.systemTemp.createTemp('mosquitto');
  // The plain MQTT listener is unused; some Mosquitto 2.0.x builds refuse to
  // start with only a websocket listener.
  final conf = File('${dir.path}/mosquitto.conf')
    ..writeAsStringSync('allow_anonymous true\n'
        'listener $mqttPort 127.0.0.1\n'
        'listener $port 127.0.0.1\n'
        'protocol websockets\n');
  final bin = Platform.environment['MOSQUITTO'] ?? 'mosquitto';

  Future<Process> start() async {
    final p = await Process.start(bin, ['-c', conf.path, '-v']);
    final out = StringBuffer();
    p.stdout.transform(const SystemEncoding().decoder).listen(out.write);
    p.stderr.transform(const SystemEncoding().decoder).listen(out.write);
    for (var i = 0; i < 100; i++) {
      try {
        (await Socket.connect(InternetAddress.loopbackIPv4, port)).destroy();
        return p;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    p.kill();
    throw StateError('mosquitto did not start on port $port.\n'
        'Config:\n${conf.readAsStringSync()}Output:\n$out');
  }

  var broker = await start();
  channel.sink.add(port);
  channel.stream.listen((msg) async {
    if (msg != 'drop') return;
    broker.kill(ProcessSignal.sigkill);
    await broker.exitCode;
    channel.sink.add('mosquitto killed (SIGKILL)');
    await Future<void>.delayed(const Duration(seconds: 2));
    broker = await start();
    channel.sink.add('mosquitto restarted');
  });
}
''';

// Records every WebSocket the page creates and the order of its events.
const _recorder = r'''
(function () {
  if (window.__wsEvents) return;
  var events = window.__wsEvents = [], n = 0, t0 = Date.now();
  function rec(s) { events.push(String(Date.now() - t0).padStart(5) + ' ms  ' + s); }
  var Orig = window.WebSocket;
  var Wrapped = function (url, protocols) {
    var id = ++n;
    var ws = protocols === undefined ? new Orig(url) : new Orig(url, protocols);
    rec('ws#' + id + ' new');
    ws.addEventListener('open', function () { rec('ws#' + id + ' open'); });
    ws.addEventListener('error', function () { rec('ws#' + id + ' error'); });
    ws.addEventListener('close', function (e) {
      rec('ws#' + id + ' close event, code ' + e.code + ', clean ' + e.wasClean);
    });
    var close = ws.close.bind(ws);
    ws.close = function () {
      rec('ws#' + id + ' close() called, readyState ' + ws.readyState);
      return close.apply(null, arguments);
    };
    return ws;
  };
  Wrapped.prototype = Orig.prototype;
  Wrapped.CONNECTING = 0; Wrapped.OPEN = 1; Wrapped.CLOSING = 2; Wrapped.CLOSED = 3;
  window.WebSocket = Wrapped;
})();
''';

@JS('__wsEvents')
external JSArray<JSString>? get _wsEvents;

void main() {
  test('auto-reconnects after the broker is killed and restarted', () async {
    web.document.head!.append(web.HTMLScriptElement()..text = _recorder);

    final broker = spawnHybridCode(_brokerCode);
    final brokerEvents = StreamIterator(broker.stream);
    expect(await brokerEvents.moveNext(), isTrue);
    final port = brokerEvents.current as int;
    final brokerLog = <String>[];
    unawaited(() async {
      while (await brokerEvents.moveNext()) {
        brokerLog.add('${brokerEvents.current}');
      }
    }());

    addTearDown(() {
      print('--- ${web.window.navigator.userAgent}');
      for (final e in _wsEvents?.toDart ?? <JSString>[]) {
        print(e.toDart);
      }
      brokerLog.forEach(print);
    });

    final client = MqttBrowserClient('ws://127.0.0.1', 'repro-client')
      ..port = port
      ..keepAlivePeriod = 60
      ..autoReconnect = true
      ..logging(on: false);
    final reconnected = Completer<void>();
    client.onAutoReconnected = () {
      if (!reconnected.isCompleted) reconnected.complete();
    };

    final status = await client.connect();
    expect(status?.state, MqttConnectionState.connected);

    // Kill the broker; the client must notice and reconnect once it is back.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    broker.sink.add('drop');
    var timedOut = false;
    await reconnected.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => timedOut = true,
    );
    expect(
      timedOut,
      isFalse,
      reason:
          'onAutoReconnected never fired '
          '(state: ${client.connectionStatus?.state})',
    );
    expect(client.connectionStatus?.state, MqttConnectionState.connected);

    client.autoReconnect = false;
    client.disconnect();
  });
}
