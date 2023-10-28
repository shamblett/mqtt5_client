import 'package:typed_data/typed_data.dart' as typed;

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';

int main() {
  group('Main', () {
    test('Chinese topic', () {
      const topic = 'smartDevices/房間1';
      final pubTopic = MqttPublicationTopic(topic);
      expect(pubTopic.hasWildcards, false);
      expect(pubTopic.rawTopic, topic);
      expect(pubTopic.toString(), topic);
    });

    test('Publish English topic', () {
      const topic = 'smartDevices';
      final pubTopic = MqttPublicationTopic(topic);
      final msg = MqttPublishMessage()
          .toTopic(pubTopic.toString())
          .withMessageIdentifier(1)
          .withQos(MqttQos.atMostOnce)
          .withUserProperties(null);

      expect(msg.variableHeader!.topicName, topic);
      final buffer = typed.Uint8Buffer();
      final byteBuffer = MqttByteBuffer(buffer);
      msg.writeTo(byteBuffer);
      byteBuffer.reset();
      final decodedMsg = MqttMessage.createFrom(byteBuffer);
      expect(decodedMsg!.header!.messageType, MqttMessageType.publish);
    });

    test('Publish Chinese topic', () {
      const topic = 'smartDevices/房間1';
      final pubTopic = MqttPublicationTopic(topic);
      final msg = MqttPublishMessage()
          .toTopic(pubTopic.toString())
          .withMessageIdentifier(1)
          .withQos(MqttQos.atMostOnce);

      expect(msg.variableHeader!.topicName, topic);
      final buffer = typed.Uint8Buffer();
      final byteBuffer = MqttByteBuffer(buffer);
      msg.writeTo(byteBuffer);
      byteBuffer.reset();

      final decodedMsg = MqttMessage.createFrom(byteBuffer);
      expect(decodedMsg!.header!.messageType, MqttMessageType.publish);
    });
  });
  return 0;
}
