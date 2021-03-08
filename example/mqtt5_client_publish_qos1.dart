/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/09/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

/// Read in conjunction with the mqtt5_server_client.dart example.
///
/// A QOS1 publishing example, two QOS one topics are subscribed to and published in quick succession,
/// tests QOS1 protocol handling.

/// Edit as needed.
const hostName = 'test.mosquitto.org';

Future<int> main() async {
  final client = MqttServerClient(hostName, '');
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('MQTT5DartClient')
      .startClean(); // Non persistent session for testing
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
    exit(-1);
  }

  /// Lets try our subscriptions
  print('EXAMPLE:: <<<< SUBCRIBE 1 >>>>');
  const topic1 = 'SJHTopic1'; // Not a wildcard topic
  client.subscribe(topic1, MqttQos.atLeastOnce);
  print('EXAMPLE:: <<<< SUBCRIBE 2 >>>>');
  const topic2 = 'SJHTopic2'; // Not a wildcard topic
  client.subscribe(topic2, MqttQos.atLeastOnce);
  // Do not subscribe to this topic.
  const topic3 = 'SJHTopic3';

  client.updates.listen((dynamic c) {
    final MqttPublishMessage recMess = c[0].payload;
    final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  // ignore: avoid_types_on_closure_parameters
  client.published!.listen((MqttPublishMessage message) {
    print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    if (message.variableHeader!.topicName == topic3) {
      print(
          'EXAMPLE::Published notification:: Non subscribed topic publication received');
    }
  });

  print(
      'EXAMPLE:: Sleeping to allow the subscription acknowledges to be received....');
  await MqttUtilities.asyncSleep(10);

  final builder1 = MqttPayloadBuilder();
  builder1.addString('Hello from mqtt_client topic 1');
  print('EXAMPLE:: <<<< PUBLISH 1 >>>>');
  client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload!);

  final builder2 = MqttPayloadBuilder();
  builder2.addString('Hello from mqtt_client topic 2');
  print('EXAMPLE:: <<<< PUBLISH 2 >>>>');
  client.publishMessage(topic2, MqttQos.atLeastOnce, builder2.payload!);

  final builder3 = MqttPayloadBuilder();
  builder3.addString('Hello from mqtt_client topic 3');
  print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIBE >>>>');
  client.publishMessage(topic3, MqttQos.atLeastOnce, builder3.payload!);

  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(60);

  print('EXAMPLE::Unsubscribing');
  client.unsubscribeStringTopic(topic1);
  client.unsubscribeStringTopic(topic2);

  await MqttUtilities.asyncSleep(2);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(MqttSubscription topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  exit(-1);
}
