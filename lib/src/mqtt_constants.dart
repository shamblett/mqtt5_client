/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// Library wide constants
class MqttConstants {
  /// The Maximum allowed message size as defined by the MQTT v5 Spec (256MB).
  static const int maxMessageSize = 268435455;

  /// The Maximum allowed client identifier length as specified by the 3.1
  /// specification is 23 characters, however we allow more than
  /// this, a warning is given in the log if 23 is exceeded.
  /// NOte: this is only a warning, it changes no client behaviour.
  static const int maxClientIdentifierLength = 1024;

  /// Maximum message binary data length
  static const maxBinaryDataLength = 65535;

  /// Minimum message binary data length
  static const minHeaderLength = 2;

  /// Minimum message binary data length
  static const minBinaryDataLength = 2;

  /// Maximum message UTF8 string length
  static const maxUTF8StringLength = 65535;

  /// Minimum message UTF8 string length
  static const minUTF8StringLength = 2;

  /// Specification length
  static const int maxClientIdentifierLengthSpec = 23;

  /// The default Mqtt port to connect to.
  static const int defaultMqttPort = 1883;

  /// The recommended length for usernames and passwords.
  static const int recommendedMaxUsernamePasswordLength = 12;

  /// Default keep alive in seconds.
  /// The value of zero disables the keep alive mechanism.
  static const int defaultKeepAlive = 0;

  /// Default maximum connection attempts
  static const int defaultMaxConnectionAttempts = 3;

  /// Default connection attempt timeout period, milliseconds,
  static const int defaultConnectionAttemptTimeoutPeriod = 5000;

  /// Disabled connection attempt timeout period, milliseconds.
  /// Used when a socket timeout period has been set.
  /// Minimum value is 1 second to allow the connect ack message to be received.
  static const int disabledConnectionAttemptTimeoutPeriod = 1000;

  static const defaultReauthenticateTimeout = 30; // seconds

  /// V4
  static const int mqttProtocolVersion = 5;

  /// V4 name
  static const String mqttProtocolName = 'MQTT';

  /// The default websocket subprotocol list
  static const List<String> protocolsMultipleDefault = <String>[
    'mqtt',
    'mqttv5',
  ];

  /// The default websocket subprotocol list for brokers who expect
  /// this field to be a single entry
  static const List<String> protocolsSingleDefault = <String>['mqtt'];

  /// Seconds to milliseconds multiplier
  static const int millisecondsMultiplier = 1000;

  /// Minimum socket timeout period
  static const minimumSocketTimeoutPeriod = 1000; //ms
}
