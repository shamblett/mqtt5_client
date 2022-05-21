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
  test('Option update', () {
    final option = MqttSubscriptionOption();
    option.retainHandling = MqttRetainHandling.doNotSendRetained;
    expect(option.retainHandling, MqttRetainHandling.doNotSendRetained);
  });

  test('Option update in subscription', () {
    final option = MqttSubscriptionOption();
    option.retainHandling = MqttRetainHandling.doNotSendRetained;
    expect(option.retainHandling, MqttRetainHandling.doNotSendRetained);
    final sub = MqttSubscription(MqttSubscriptionTopic("tinydb"), option);
    expect(sub.option!.retainHandling, MqttRetainHandling.doNotSendRetained);
  });

  test('Subscribe with option', () async {
    final client = MqttServerClient.withPort(
        'test.mosquitto.org', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: true);
    await client.connect();
    final option = MqttSubscriptionOption();
    option.retainHandling = MqttRetainHandling.doNotSendRetained;
    expect(option.retainHandling, MqttRetainHandling.doNotSendRetained);
    final sub = MqttSubscription(MqttSubscriptionTopic("tinydb"), option);
    client.subscribeWithSubscription(sub);
    expect(sub.option?.retainHandling, MqttRetainHandling.doNotSendRetained);
    client.disconnect();
  });

  return 0;
}
