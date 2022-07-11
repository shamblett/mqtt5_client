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

/// An annotated simple subscribe/publish usage example for mqtt5_server_client. Please read in with reference
/// to the MQTT 5 specification. The example is runnable against any suitable MQTT5 broker such as Mosquitto
/// or Hive, please edit the hostname as required.

/// First create a client, the client is constructed with a broker name, client identifier
/// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
/// client connecting to an MQTT broker. As the word identifier already suggests, it should be unique per client connection.
/// The broker uses it for identifying the client and the current state(session) of the client.
///
/// If a port is not specified the standard port of 1883 is used.
///
/// If you want to use websockets rather than TCP see below. A separate example(mqtt5_server_client_secure.dart')
/// shows how to set up and use secure sockets on the server.

/// Edit as needed.
const hostName = 'test.mosquitto.org';

final client = MqttServerClient(hostName, '');
const pubTopic = 'Dart/Mqtt5_client/testtopic';
bool topicNotified = false;
final builder = MqttPayloadBuilder();

Future<int> main() async {
  /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
  /// for details.
  ///
  /// To use websockets add the following lines -:
  /// client.useWebSocket = true;
  /// client.port = 80;  ( or whatever your WS port is).
  ///
  /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
  /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
  /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
  /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
  /// list so in most cases you can ignore this.

  /// Set logging on if needed, defaults to off
  client.logging(on: false);

  /// If you intend to use a keep alive value in your connect message that is not the default(60s)
  /// you must set it here
  client.keepAlivePeriod = 60;

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  /// Add the successful connection callback
  client.onConnected = onConnected;

  /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
  /// You can add these before connection or change them dynamically after connection if
  /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
  /// can fail either because you have tried to subscribe to an invalid topic or the broker
  /// rejects the subscribe request.
  client.onSubscribed = onSubscribed;

  /// Set a ping received callback if needed, called whenever a ping response(pong) is received
  /// from the broker.
  client.pongCallback = pong;

  /// Create a connection message to use or use the default one. The default one sets the
  /// client identifier, any supplied username/password, the default keepalive interval(60s)
  /// and clean session, an example of a specific one below.
  /// Add some user properties, these may be available in the connect acknowledgement.
  /// Note there are many otions selectable on this message, if you opt to use authentication please see
  /// the example in mqtt5_server_client_authenticate.dart.
  final property = MqttUserProperty();
  property.pairName = 'Example name';
  property.pairValue = 'Example value';
  final connMess = MqttConnectMessage()
      .withClientIdentifier('MQTT5DartClient')
      .startClean() // Or startSession() for a persistent session
      .withUserProperties([property]);
  print('EXAMPLE::Mqtt5 client connecting....');
  client.connectionMessage = connMess;

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// its possible that in some circumstances the broker will just disconnect us, see the spec about this,
  /// we however will never send malformed messages.
  try {
    await client.connect();
  } on MqttNoConnectionException catch (e) {
    // Raised by the client when connection fails.
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  } on SocketException catch (e) {
    // Raised by the socket layer
    print('EXAMPLE::socket exception - $e');
    client.disconnect();
  }

  /// Check we are connected. connectionStatus always gives us this and other information.
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print(
        'EXAMPLE::Mqtt5 server client connected, return code is ${client.connectionStatus!.reasonCode.toString().split('.')[1]}');

    /// All returned properties in the connect acknowledge message are available.
    /// Get our user properties from the connect acknowledge message.
    if (client.connectionStatus!.connectAckMessage.userProperty!.isNotEmpty) {
      print(
          'EXAMPLE::Connected - user property name - ${client.connectionStatus!.connectAckMessage.userProperty![0].pairName}');
      print(
          'EXAMPLE::Connected - user property value - ${client.connectionStatus!.connectAckMessage.userProperty![0].pairValue}');
    }
  } else {
    print(
        'EXAMPLE::ERROR Mqtt5 client connection failed - status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  /// Ok, lets try a subscription
  print('EXAMPLE::Subscribing to the test/lol topic');
  const topic = 'test/lol'; // Not a wildcard topic
  client.subscribe(topic, MqttQos.atMostOnce);

  /// The client has a change notifier object(see the Observable class) which we then listen to to get
  /// notifications of published updates to each subscribed topic.
  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic
    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');

    /// Indicate the notification is correct
    if (c[0].topic == pubTopic) {
      topicNotified = true;
    }
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  client.published!.listen((MqttPublishMessage message) {
    print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
  });

  /// Subscribe to our topic, we will publish to it in the onSubscribed callback.
  print('EXAMPLE::Subscribing to the Dart/Mqtt5_client/testtopic topic');
  client.subscribe(pubTopic, MqttQos.exactlyOnce);

  /// Ok, we will now sleep a while, in this gap you will see ping request/response
  /// messages being exchanged by the keep alive mechanism.
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(120);

  /// Finally, unsubscribe and exit gracefully
  print('EXAMPLE::Unsubscribing');
  client.unsubscribeStringTopic(topic);

  /// Wait for the unsubscribe acknowledge message from the broker.
  /// We could also add an unsubscribe callback and do the disconnect in it.
  await MqttUtilities.asyncSleep(2);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(MqttSubscription subscription) {
  print(
      'EXAMPLE::Subscription confirmed for topic ${subscription.topic.rawTopic}');

  /// Publish to our topic if it has been subscribed
  if (subscription.topic.rawTopic == pubTopic) {
    /// Use the payload builder rather than a raw buffer
    builder.addString('Hello from mqtt5_client');
    print('EXAMPLE::Publishing our topic now we are subscribed');
    client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  if (client.connectionStatus!.disconnectionOrigin ==
      MqttDisconnectionOrigin.solicited) {
    if (topicNotified) {
      print(
          'EXAMPLE::OnDisconnected callback is solicited, topic has been notified - this is correct');
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is solicited, topic has NOT been notified - this is an ERROR');
    }
  }
  exit(0);
}

/// The successful connect callback
void onConnected() {
  print(
      'EXAMPLE::OnConnected client callback - Client connection was successful');
}

/// Pong callback
void pong() {
  print('EXAMPLE::Ping response client callback invoked');
}
