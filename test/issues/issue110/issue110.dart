/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

/// To test the auto reconnect feature this example uses a Mosquitto broker running on local host, any will do
/// as long as you can break its connection to this process. You could wait for the first pong callback to print out
/// (these are every 5 seconds) then stop/break connection to the server and reinstate it.
///
final clientA = MqttServerClient('localhost', '');
final clientB = MqttServerClient('test.mosquitto.org', '');

Future<int> main() async {
  /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
  /// for details.
  /// To use websockets add the following lines -:
  /// client.useWebSocket = true;
  /// client.port = 80;  ( or whatever your WS port is)
  /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
  /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
  /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
  /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
  /// list so in most cases you can ignore this.

  /// Set logging on if needed, defaults to off
  clientA.logging(on: true);
  clientB.logging(on: true);

  /// The client keep alive mechanism is defaulted to off, to enable it set [keepAlivePeriod] below to
  /// a positive value other than 0.
  clientA.keepAlivePeriod = 5;
  clientB.keepAlivePeriod = 5;

  /// Set auto reconnect
  clientA.autoReconnect = true;

  /// If you do not want active confirmed subscriptions to be automatically re subscribed
  /// by the auto connect sequence do the following, otherwise leave this defaulted.
  clientA.resubscribeOnAutoReconnect = false;

  /// Add an auto reconnect callback.
  /// This is the 'pre' auto re connect callback, called before the sequence starts.
  clientA.onAutoReconnect = onAutoReconnect;

  /// Add an auto reconnect callback.
  /// This is the 'post' auto re connect callback, called after the sequence
  /// has completed. Note that re subscriptions may be occurring when this callback
  /// is invoked. See [resubscribeOnAutoReconnect] above.
  clientA.onAutoReconnected = onAutoReconnected;

  /// Add the successful connection callback if you need one.
  /// This will be called after [onAutoReconnect] but before [onAutoReconnected]
  clientA.onConnected = onConnectedA;
  clientB.onConnected = onConnectedB;

  /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
  /// You can add these before connection or change them dynamically after connection if
  /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
  /// can fail either because you have tried to subscribe to an invalid topic or the broker
  /// rejects the subscribe request.
  clientA.onSubscribed = onSubscribed;

  /// Set a ping received callback if needed, called whenever a ping response(pong) is received
  /// from the broker.
  clientA.pongCallback = pong;

  /// Create a connection message to use or use the default one. The default one sets the
  /// client identifier, any supplied username/password, the default keepalive interval(60s)
  /// and clean session, an example of a specific one below.
  final connMessA = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueIdA')
      .startClean(); // Non persistent session for testing
  clientA.connectionMessage = connMessA;

  final connMessB = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueIdB')
      .startClean(); // Non persistent session for testing
  print('EXAMPLE::Mosquitto client connecting....');
  clientB.connectionMessage = connMessB;

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
  /// never send malformed messages.
  print('EXAMPLE::Mosquitto client A connecting....');
  try {
    await clientA.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client A exception - $e');
    clientA.disconnect();
  }

  /// Check we are connected
  if (clientA.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client A connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client A connection failed - disconnecting, status is ${clientA.connectionStatus}');
    clientA.disconnect();
    exit(-1);
  }

  /// Ok, lets try a subscription
  print('EXAMPLE::Subscribing to the test/lol topic');
  const topic = 'test/lol'; // Not a wildcard topic
  clientA.subscribe(topic, MqttQos.atMostOnce);

  /// The client has a change notifier object(see the Observable class) which we then listen to to get
  /// notifications of published updates to each subscribed topic.
  clientA.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  clientA.published!.listen((MqttPublishMessage message) {
    print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
  });

  /// Lets publish to our topic
  /// Use the payload builder rather than a raw buffer
  /// Our known topic to publish to
  const pubTopic = 'Dart/Mqtt_client/testtopic';
  final builder = MqttPayloadBuilder();
  builder.addString('Hello from mqtt_client');

  /// Subscribe to it
  print('EXAMPLE::Subscribing to the Dart/Mqtt_client/testtopic topic');
  clientA.subscribe(pubTopic, MqttQos.exactlyOnce);

  /// Publish it
  print('EXAMPLE::Publishing our topic');
  clientA.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

  /// Ok, we will now sleep a while, in this gap you will see ping request/response
  /// messages being exchanged by the keep alive mechanism.
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(120);

  /// Finally, unsubscribe and exit gracefully
  print('EXAMPLE::Unsubscribing');
  clientA.unsubscribeStringTopic(topic);

  /// Wait for the unsubscribe message from the broker if you wish.
  await MqttUtilities.asyncSleep(2);
  print('EXAMPLE::Disconnecting');
  clientA.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(MqttSubscription subscription) {
  print(
      'EXAMPLE::Subscription confirmed for topic ${subscription.topic.rawTopic}');
}

// The pre auto re connect callback
void onAutoReconnect() {
  print(
      'EXAMPLE::onAutoReconnect client A callback - Client auto reconnection sequence will start');
}

/// The post auto re connect callback
void onAutoReconnected() async {
  print(
      'EXAMPLE::onAutoReconnected client callback - Client A auto reconnection sequence has completed');
  clientA.disconnect();
  print('EXAMPLE::Mosquitto client A connecting....');
  try {
    await clientB.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client B exception - $e');
    clientB.disconnect();
  }

  /// Check we are connected
  if (clientB.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client B connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client B connection failed - disconnecting, status is ${clientB.connectionStatus}');
    clientB.disconnect();
    exit(-1);
  }
}

/// The successful connect callback
void onConnectedA() {
  print(
      'EXAMPLE::OnConnected client A callback - Client connection was successful');
}

// The successful connect callback
void onConnectedB() {
  print(
      'EXAMPLE::OnConnected client B callback - Client connection was successful');
}

/// Pong callback
void pong() {
  print(
      'EXAMPLE::Ping response client callback invoked - you may want to disconnect your broker here');
}
