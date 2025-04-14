import 'package:mqtt5_client/mqtt5_client.dart' as mqtt;
import 'package:mqtt5_client/mqtt5_server_client.dart' as mqtt;

Future<void> main() async {
  final client =
      mqtt.MqttServerClient.withPort(
          'wss://test.mosquitto.org/mqtt',
          'test-b',
          8081,
        )
        ..useWebSocket = true
        ..connectionMessage = mqtt.MqttConnectMessage()
            .will()
            .withWillQos(mqtt.MqttQos.exactlyOnce)
            .withWillTopic('mqtt5_client/test/disconnect_with_will')
            .withWillPayload(
              (() {
                final builder = mqtt.MqttPayloadBuilder();
                builder.addString('TEST DISCONNECTED');
                return builder.payload!;
              })(),
            )
        ..disconnectMessage = mqtt.MqttDisconnectMessage().withReasonCode(
          mqtt.MqttDisconnectReasonCode.disconnectWithWillMessage,
        )
        ..onConnected = () {
          print('onConnected');
        }
        ..onDisconnected = () {
          print('onDisconnected');
        };

  await client.connect();

  final id = client.publishMessage(
    'mqtt5_client/test/disconnect_with_will',
    mqtt.MqttQos.atMostOnce,
    (() {
      final builder = mqtt.MqttPayloadBuilder();
      builder.addString('TEST CONNECTED AT ${DateTime.now()}');
      return builder.payload!;
    })(),
  );
  print('Published: $id');

  await Future.delayed(const Duration(seconds: 2)); // Some delay just in case

  client.disconnect();
}
