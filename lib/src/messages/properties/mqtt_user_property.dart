/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A user property.
/// This is a convenience extension of a string pair property to allow more
/// logical setting of user properties.
class MqttUserProperty extends MqttStringPairProperty {
  MqttUserProperty() : super(MqttPropertyIdentifier.userProperty);
}
