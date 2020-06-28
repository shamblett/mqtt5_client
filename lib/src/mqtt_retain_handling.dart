/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Enumeration of available rertain handling types.
enum MqttRetainHandling {
  /// Send retained messages at the time of the subscribe.
  sendRetained,

  /// Send retained messages at subscribe only if the subscription
  /// does not currently exist.
  sendRetainedOnlyIfNotExist,

  /// Do not send retained messages at the time of the subscribe.
  doNotSendRetained
}
