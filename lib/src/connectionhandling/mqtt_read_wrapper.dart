/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// State and logic used to read from the underlying network stream.
class MqttReadWrapper {
  /// Creates a new ReadWrapper that wraps the state used to read
  /// a message from a stream.
  MqttReadWrapper() {
    messageBytes = <int>[];
  }

  /// The bytes associated with the message being read.
  List<int>? messageBytes;
}
