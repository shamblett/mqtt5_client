import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';

int main() {
  test('Topic match fail', () {
    final sub = MqttSubscriptionTopic("test/test1/a/b");
    final pub = MqttPublicationTopic("test");
    sub.matches(pub);
  });

  return 0;
}
