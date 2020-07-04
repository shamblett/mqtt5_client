/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Message identifier handling
class MqttMessageIdentifierDispenser {
  /// Factory constructor
  factory MqttMessageIdentifierDispenser() => _singleton;

  MqttMessageIdentifierDispenser._internal();

  static final MqttMessageIdentifierDispenser _singleton =
      MqttMessageIdentifierDispenser._internal();

  /// Maximum message identifier
  static const int maxMessageIdentifier = 32768;

  /// Initial value
  static const int initialValue = 0;

  /// Minimum message identifier
  static const int startMessageIdentifier = 1;

  /// Message identifier, zero is forbidden
  int _mid = initialValue;

  /// Mid
  int get mid => _mid;

  /// Gets the next message identifier
  int get nextMessageIdentifier {
    _mid++;
    if (_mid == maxMessageIdentifier) {
      _mid = startMessageIdentifier;
    }
    return mid;
  }

  /// Resets the mid
  void reset() {
    _mid = initialValue;
  }
}
