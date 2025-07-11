import 'dart:async';

import 'package:mqtt5_client/mqtt5_browser_client.dart';
import 'package:mqtt5_client/mqtt5_client.dart';

class MqttParams {
  final url = 'ws://test.mosquitto.org';
  final port = 8080;
  final keepAlivePeriod = 60;
  final username = null;
  final password = null;
}

class MqttWebInitializer {
  late MqttBrowserClient _client;

  void initClient({
    required MqttParams params,
    String willTopic = 'willTopic',
    String willMessage = 'will message',
  }) {
    _client = MqttBrowserClient(params.url, '');
    final clientId = 'Geppo-Web}';
    _client.logging(on: false);
    _client.port = params.port;
    _client.websocketProtocols = MqttConstants.protocolsSingleDefault;
    // Keep alive period (in secondi) a 0 = disabilitato
    if (params.keepAlivePeriod > 0) {
      _client.keepAlivePeriod = params.keepAlivePeriod;
    }
    _client.onDisconnected = onDisconnected;
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;
    _client.onUnsubscribed = onUnsubscribed;

    final MqttConnectMessage connectMessage = MqttConnectMessage();
    if (params.username != null && params.password != null) {
      connectMessage.authenticateAs(params.username!, params.password!);
    }
    connectMessage.withClientIdentifier(clientId).startClean();

    print('EXECUTING - MQTT CONNECT...');
    _client.connectionMessage = connectMessage;
  }

  MqttClient get client => _client;

  Future<MqttConnectionStatus?> connect([
    String? username,
    String? password,
  ]) async {
    MqttConnectionStatus? status;
    try {
      print('EXECUTING - MQTT CONNECTING...');

      if (username == null && password == null) {
        status = await _client.connect(username, password);
      } else {
        status = await _client.connect();
      }
    } catch (e) {
      print('EXCEPTION - MQTT CONNECT: $e');
    }
    return status;
  }

  void disconnect() {
    print('EXECUTING - MQTT DISCONNECTING...');
    _client.disconnect();
  }

  void onConnected() {
    print('EXECUTING - MQTT CONNECTED');
  }

  void onDisconnected() {
    print('EXECUTING - MQTT DISCONNECTED');
  }

  void onSubscribed(MqttSubscription sub) {
    print('EXECUTING - MQTT SUBSCRIBED TO TOPIC: ${sub.topic}');
  }

  void onUnsubscribed(MqttSubscription sub) {
    print('EXECUTING - MQTT UNSUBSCRIBED FROM TOPIC: ${sub.topic}');
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.exactlyOnce}) {
    print('EXECUTING - MQTT SUBSCRIBING TO TOPIC: $topic');
    _client.subscribe(topic, qos);
  }

  void unsubscribe(String topic) {
    print('EXECUTING - MQTT UNSUBSCRIBED FROM TOPIC: $topic');
    _client.unsubscribeStringTopic(topic);
  }
}

void main() async {
  final browser = MqttWebInitializer();
  browser.initClient(params: MqttParams());
  print('EXECUTING - Connecting');
  await browser.connect();
  print('EXECUTING - Waiting before subscription');
  await Future.delayed(Duration(seconds: 5));
  browser.subscribe('my/dashboard/topic/chatList/#', qos: MqttQos.exactlyOnce);
  print('EXECUTING - Subscribed - waiting for disconnect');
  await Future.delayed(Duration(seconds: 10));
  browser.unsubscribe('my/dashboard/topic/chatList/#');
  browser.disconnect();
}
