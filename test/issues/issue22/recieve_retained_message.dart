import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:test/test.dart';

Future<int> main() async {
  recieveRetainedMessageTest(int retainDelay) async {
    final client = MqttServerClient("test.mosquitto.org", "");

    String topic = "iWantToBeRetained";
    var sendData = Uint8Buffer();
    sendData.add(255); //Super unique data
    Uint8Buffer? recvData;

    await client.connect();
    print("Publishing Message: $sendData at $topic");
    client.publishMessage(topic, MqttQos.exactlyOnce, sendData, retain: true);

    print("Waiting for $retainDelay seconds before subscribing");
    await MqttUtilities.asyncSleep(retainDelay);

    client.subscribe(topic, MqttQos.exactlyOnce);
    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final data = (c[0].payload as MqttPublishMessage).payload.message!;
      print("Recieved Message: ${data} at ${c[0].topic}");
      if (c[0].topic == topic) {
        recvData = data;
      }
    });

    // Give some time to the broker for a response
    await MqttUtilities.asyncSleep(1);
    if (recvData == null) {
      print("*** ERROR *** - Nothing was recieved!");
      client.disconnect();
      return -1;
    }

    expect(recvData, sendData);

    client.unsubscribeStringTopic(topic);
    client.disconnect();
  }

  test("Get a retained message right after its published", () => recieveRetainedMessageTest(0));

  test("Get a retained message after a delay", () => recieveRetainedMessageTest(1));

  return 0;
}