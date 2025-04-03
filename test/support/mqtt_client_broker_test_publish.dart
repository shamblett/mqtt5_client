/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

Future<int> main() async {
  // Create and connect the client
  final client = MqttServerClient('iot.eclipse.org', 'SJHMQTTClient');
  client.logging(on: true);
  await client.connect();
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Mosquitto client connected');
  } else {
    print(
      'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus}',
    );
    client.disconnect();
  }
  // Publish a known topic
  const topic = 'Dart/SJH/mqtt_client';
  final buff = typed.Uint8Buffer(5);
  buff[0] = 'h'.codeUnitAt(0);
  buff[1] = 'e'.codeUnitAt(0);
  buff[2] = 'l'.codeUnitAt(0);
  buff[3] = 'l'.codeUnitAt(0);
  buff[4] = 'o'.codeUnitAt(0);
  client.publishMessage(topic, MqttQos.exactlyOnce, buff);
  print('Sleeping....');
  await MqttUtilities.asyncSleep(10);
  print('Disconnecting');
  client.disconnect();
  return 0;
}
