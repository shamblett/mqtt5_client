/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Represents a MQTT message that has been received from a broker.
class MqttReceivedMessage<T> {
  /// Initializes a new instance of an MqttReceivedMessage class.
  MqttReceivedMessage(this.topic, this.payload);

  /// The topic the message was received on.
  String? topic;

  /// The payload of the message received.
  T payload;
}
