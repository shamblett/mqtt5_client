/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';

/// An annotated connection attempt failed usage example for mqtt5_server_client.
///
/// To run this example on a linux host please execute 'netcat -l 1883' at the command line.
/// Use a suitably equivalent command for other hosts.
///
/// First create a client, the client is constructed with a broker name, client identifier
/// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
/// client connecting to an MQTT broker. As the word identifier already suggests, it should be unique per client connection.
/// The broker uses it for identifying the client and the current state(session) of the client.
///
/// If a port is not specified the standard port of 1883 is used.
///
/// If you want to use websockets rather than TCP see below. A separate example(mqtt5_server_client_secure.dart')
/// shows how to set up and use secure sockets on the server.

/// Connect to a resolvable host that is not running a broker, hence the connection will fail.
/// Set the maximum connection attempts to 3.
final client = MqttServerClient('localhost', '', maxConnectionAttempts: 3);

Future<int> main() async {
  /// Set logging on if needed, defaults to off
  client.logging(on: false);

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  /// Add the failed connection attempt callback.
  /// This callback will be called on every failed connection attempt, in the case of this
  /// example it will be called 3 times at a period of 2 seconds.
  client.onFailedConnectionAttempt = failedConnectionAttemptCallback;

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

  /// Connect the client, any errors here are communicated via the failed
  /// connection attempts callback

  try {
    await client.connect();
  } on MqttNoConnectionException catch (e) {
    // Raised by the client when connection fails.
    print('EXAMPLE::client exception - $e');
    client.disconnect();
    exit(-1);
  } on SocketException catch (e) {
    // Raised by the socket layer
    print('EXAMPLE::socket exception - $e');
    client.disconnect();
    exit(-1);
  }

  /// Check we are not connected
  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client not connected');
  }

  exit(0);
}

/// Failed connection attempt callback
void failedConnectionAttemptCallback(int attempt) {
  print('EXAMPLE::onFailedConnectionAttempt, attempt number is $attempt');
  if (attempt == 3) {
    client.disconnect();
  }
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  if (client.connectionStatus!.disconnectionOrigin ==
      MqttDisconnectionOrigin.solicited) {
    print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
  } else {
    print(
        'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
    exit(-1);
  }
}
