/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Describes the status of a subscription
enum MqttSubscriptionStatus {
  /// The subscription does not exist / is not known
  doesNotExist,

  /// The subscription is currently pending acknowledgement by a broker.
  pending,

  /// The subscription is currently active and messages will be received.
  active
}
