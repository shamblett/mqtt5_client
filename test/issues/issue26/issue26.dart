import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:test/test.dart';

Future<int> main() async {
  resubscribeAfterUnsubscribe(
      String broker_url, int port, bool useWs, int delay) async {
    final client = MqttServerClient(broker_url, "");
    client.useWebSocket = useWs;
    client.port = port;
    client.logging(on: true);

    String topic = "iWantToBeUnsubscribed";
    var sendData = Uint8Buffer();

    await client.connect();

    client.subscribe(topic, MqttQos.exactlyOnce);

    print("Waiting for $delay seconds before unsubscribing");
    await MqttUtilities.asyncSleep(delay);

    client.unsubscribeStringTopic(topic);

    print("Waiting for $delay seconds after unsubscribing");
    await MqttUtilities.asyncSleep(delay);

    var subStatus =
        client.subscriptionsManager!.getSubscriptionTopicStatus(topic);
    print(subStatus);

    expect(subStatus, MqttSubscriptionStatus.doesNotExist);

    client.disconnect();
  }

  //test("[broker.emqx.io] websocket unsubscribe", () => resubscribeAfterUnsubscribe("ws://broker.emqx.io/mqtt", 8083, true, 0));

  test(
      "[broker.emqx.io] websocket unsubscribe after a delay",
      () => resubscribeAfterUnsubscribe(
          "ws://broker.emqx.io/mqtt", 8083, true, 5));

  //test("[broker.hivemq.com] websocket unsubscribe right after its published", () =>
  //  resubscribeAfterUnsubscribe("ws://broker.hivemq.com/mqtt", 8000, true, 0));

  test(
      "[broker.hivemq.com] websocket unsubscribe after a delay",
      () => resubscribeAfterUnsubscribe(
          "ws://broker.hivemq.com/mqtt", 8000, true, 5));

  return 0;
}
