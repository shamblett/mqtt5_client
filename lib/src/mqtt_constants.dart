/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Library wide constants
class MqttConstants {
  /// The Maximum allowed message size as defined by the MQTT v3 Spec (256MB).
  static const int maxMessageSize = 268435455;

  /// The Maximum allowed client identifier length as specified by the 3.1
  /// specification is 23 characters, however we allow more than
  /// this, a warning is given in the log if 23 is exceeded.
  /// NOte: this is only a warning, it changes no client behaviour.
  static const int maxClientIdentifierLength = 1024;

  /// Specification length
  static const int maxClientIdentifierLengthSpec = 23;

  /// The default Mqtt port to connect to.
  static const int defaultMqttPort = 1883;

  /// The recommended length for usernames and passwords.
  static const int recommendedMaxUsernamePasswordLength = 12;

  /// Default keep alive in seconds
  static int defaultKeepAlive = 60;

  /// V4
  static const int mqttProtocolVersion = 5;

  /// V4 name
  static const String mqttProtocolName = 'MQTT';

  /// The default websocket subprotocol list
  static const List<String> protocolsMultipleDefault = <String>[
    'mqtt',
    'mqttv5'
  ];

  /// The default websocket subprotocol list for brokers who expect
  /// this field to be a single entry
  static const List<String> protocolsSingleDefault = <String>['mqtt'];
}
