/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An individual subscription as used by the client to build and track
/// the status of subscriptions and unsubscriptions.
class MqttSubscription {
  /// Construction with an optional option
  MqttSubscription(this.topic, [this.option]) {
    option ??= MqttSubscriptionOption();
    createdTime = DateTime.now();
  }

  /// With a maximum qos
  MqttSubscription.withMaximumQos(this.topic, MqttQos? qos) {
    option = MqttSubscriptionOption();
    option!.maximumQos = qos;
    createdTime = DateTime.now();
  }

  /// The time the subscription was created or for an unsubscribe
  /// the unsubscription time.
  late DateTime createdTime;

  /// The topic that is subscribed to or unsubscribed from.
  MqttSubscriptionTopic topic;

  /// The maximum QOS level of the topic for subscriptions.
  MqttQos? get maximumQos => option!.maximumQos;
  set maximumQos(MqttQos? qos) => option!.maximumQos = qos;

  /// The subscription topic option for subscriptions
  MqttSubscriptionOption? option;

  /// The subscribe reason code as returned by a either a subscribe acknowledgement
  /// message or an unsubscribe acknowledgement message.
  /// Note that for an unsubscribe operation if the reason code indicates a
  /// failure the client will still locally unsubscribe the topic.
  MqttSubscribeReasonCode? reasonCode = MqttSubscribeReasonCode.notSet;

  /// User properties as supplied in subscribe or unsubscribe operations
  /// or as received in subscribe acknowledge or unsubscribe acknowledge
  /// messages.
  List<MqttUserProperty>? userProperties;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MqttSubscription && topic == other.topic;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Topic = ${topic.toString()}');
    sb.writeln('Maximum Qos = ${maximumQos.toString()}');
    sb.writeln('Created Time = ${createdTime.toString()}');
    return sb.toString();
  }

  @override
  int get hashCode => super.hashCode * 8;
}
