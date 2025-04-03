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
import 'package:typed_data/typed_buffers.dart';

/// An annotated example showing how to use the authentication message and authentication sequences.

/// Edit as needed.
const hostName = 'localhost';

final client = MqttServerClient(hostName, '');

Future<int> main() async {
  /// Set logging on if needed, defaults to off
  client.logging(on: true);

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  /// Add the successful connection callback
  client.onConnected = onConnected;

  /// Create a connection message to use or use the default one.
  /// To initiate an authentication sequence an authentication method must be set, this can also be
  /// augmented with authentication data and other authentication related settings.
  final connMess = MqttConnectMessage()
      .withClientIdentifier('MQTT5DartClient')
      .startClean() // Or startSession() for a persistent session
      .withAuthenticationMethod('SCRAM-SHA-1')
      .withAuthenticationData(Uint8Buffer()..addAll([1, 2, 3, 4]));
  client.connectionMessage = connMess;

  /// Authentication message exchange can occur between the sending of the connect message and reception of the
  /// corresponding connect acknowledge message, to cater for this we must listen for incoming authentication messages,
  /// pre connecting.
  client.authentication!.listen((final authMessage) {
    print('EXAMPLE:: Authentication Message received - $authMessage');

    /// Authentication message received, do what you need to do here, we simply tell the broker the sequence has ended.
    authMessage.withReasonCode(MqttAuthenticateReasonCode.success);
    client.sendAuthenticate(authMessage);
  });

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// its possible that in some circumstances the broker will just disconnect us, see the spec about this,
  /// we however will never send malformed messages.
  print('EXAMPLE::Mqtt5 client connecting....');
  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
    exit(-1);
  }

  /// Check we are connected. connectionStatus always gives us this and other information.
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print(
      'EXAMPLE::Mqtt5 server client connected, return code is ${client.connectionStatus!.reasonCode.toString().split('.')[1]}',
    );
  } else {
    print(
      'EXAMPLE::ERROR Mqtt5 client connection failed - status is ${client.connectionStatus}',
    );
    client.disconnect();
    exit(-1);
  }

  /// Wait a little while then reauthenticate.
  await MqttUtilities.asyncSleep(10);

  /// We can re-authenticate periodically as needed. Send an authentication message and await the reply.
  /// Note you can also just use the sendAuthenticate method and handle the reply in your listener,
  /// the reauthenticate method is supplied as a convenience. Note you are responsible for building the message
  /// as you wish.
  final authMessage = MqttAuthenticateMessage()
      .withAuthenticationMethod('SCRAM-SHA-1')
      .withAuthenticationData(Uint8Buffer()..addAll([1, 2, 3, 4]))
      .withReasonCode(MqttAuthenticateReasonCode.reAuthenticate);

  /// Reauthenticate, if an authenticate reply is received first check the timeout indicator,
  /// if true the broker has not replied to the request. The default timeout is 30 seconds, set
  /// this as you wish.
  print('EXAMPLE::Reauthenticating');
  final reAuthMessage = await client.reauthenticate(
    authMessage,
    waitTimeInSeconds: 5,
  );
  if (reAuthMessage.timeout) {
    print('EXAMPLE::Reauthenticate timeout, broker did not reply.');
  } else {
    print('EXAMPLE::Reauthenticate - sending reply');

    /// Do what you need to here, we can just reply with success.
    authMessage.withReasonCode(MqttAuthenticateReasonCode.success);
    client.sendAuthenticate(authMessage);
  }

  /// Wait a while then gracefully exit
  await MqttUtilities.asyncSleep(10);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  if (client.connectionStatus!.disconnectionOrigin ==
      MqttDisconnectionOrigin.solicited) {
    print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
  }
}

/// The successful connect callback
void onConnected() {
  print(
    'EXAMPLE::OnConnected client callback - Client connection was successful',
  );
}
