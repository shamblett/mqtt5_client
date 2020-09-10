/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';

Future<int> main() async {
  test('Should try three times then fail', () async {
    final client =
        MqttServerClient.withPort('billy', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: true);

    // Main test starts here
    print('ISSUE: Main test start');
    var exceptionOK = false;
    try {
      await client.connect();
    } on SocketException {
      exceptionOK = true;
    }
    expect(exceptionOK, isTrue);
    expect(client.connectionStatus.state, MqttConnectionState.faulted);
    print('ISSUE: Test complete');
  });

  return 0;
}
