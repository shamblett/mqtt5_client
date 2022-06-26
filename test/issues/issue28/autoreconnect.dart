/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';

Future<int> main() async {
  test('Should resume persistent session after auto reconnect', () async {
    final client = MqttServerClient.withPort('localhost', 'SJHIssueRx', 1883);
    client.autoReconnect = true;
    client.logging(on: false);
    const topic = 'counter';

    print('ISSUE: Connecting');
    await client.connect();

    // Subscribe to counter, Qos 1
    client.subscribe(topic, MqttQos.atLeastOnce);
    print(
        'EXAMPLE:: Sleeping to allow the subscription acknowledges to be received....');
    await MqttUtilities.asyncSleep(2);

    // Listen for the counter messages
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = recMess.payload.message;
      if (payload != null) {
        final counterValue = payload[0];
        print('ISSUE::Change notification:: counter received is $counterValue');
      } else {
        print('ISSUE - ERROR payload is null');
      }
    });

    print('ISSUE: Test complete');
  }, timeout: Timeout(Duration(seconds: 40)));

  return 0;
}
