/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An individual subscription as used by the client to build and track
/// the status of subscription and unsubscription messages.
class MqttSubscription extends Object
    with observe.Observable<observe.ChangeRecord> {
  /// Construction with an optional option
  MqttSubscription(this.topic, [this.option]) {
    option ??= MqttSubscriptionOption();
    createdTime = DateTime.now();
  }

  /// With a maximum qos
  MqttSubscription.withMaximumQos(this.topic, MqttQos qos) {
    option = MqttSubscriptionOption();
    option.maximumQos = qos;
    createdTime = DateTime.now();
  }

  /// The time the subscription was created.
  DateTime createdTime;

  /// The topic that is subscribed to.
  MqttSubscriptionTopic topic;

  /// The maximum QOS level of the topic subscription.
  MqttQos get maximumQos => option.maximumQos;
  set maximumQos(MqttQos qos) => option.maximumQos = qos;

  /// The subscription topic option
  MqttSubscriptionOption option;

  /// The subscribe reason code as returned by a either a subscribe acknowledgement
  /// message or an unsubscribe acknowledgement message.
  MqttSubscribeReasonCode reasonCode = MqttSubscribeReasonCode.notSet;

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
}
