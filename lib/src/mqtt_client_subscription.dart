/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Entity that captures data related to an individual subscription
class Subscription extends Object
    with observe.Observable<observe.ChangeRecord> {
  /// The message identifier assigned to the subscription
  int messageIdentifier;

  /// The time the subscription was created.
  DateTime createdTime;

  /// The Topic that is subscribed to.
  MqttSubscriptionTopic topic;

  /// The QOS level of the topics subscription
  MqttQos qos;
}
