import 'dart:async';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

const hostName = 'localhost';

Future<int> main() async {
  final client = MqttServerClient.withPort(hostName, 'SJHIssueTx', 1883);
  client.logging(on: false);
  final connMess = MqttConnectMessage();
  connMess.startSession();
  client.connectionMessage = connMess;

  const topic = 'counter';

  print('ISSUE:: client connecting....');
  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('ISSUE:: client connected');
  } else {
    print(
        'ISSUE::ERROR client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
    exit(-1);
  }

  // Send the counter values
  for (var x = 1; x < 100; x++) {
    await MqttUtilities.asyncSleep(1);
    final builder = MqttPayloadBuilder();
    builder.addByte(x);
    print('ISSUE:: Publishing counter value ${builder.payload!}');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  await MqttUtilities.asyncSleep(2);
  print('ISSUE::Disconnecting');
  client.disconnect();
  return 0;
}
