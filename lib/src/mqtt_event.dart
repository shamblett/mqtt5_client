/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The message available event.
class MqttMessageAvailable {
  /// Constructor
  MqttMessageAvailable(this._message);

  /// The message associated with the event
  final MqttMessage _message;

  /// Message
  MqttMessage get message => _message;
}

/// Message recieved for publishing event.
class MqttMessageReceived {
  /// Constructor
  MqttMessageReceived(this._topic, this._message);

  /// The message associated with the event
  final MqttMessage _message;

  /// Message
  MqttMessage get message => _message;

  /// The topic
  final MqttPublicationTopic _topic;

  /// Topic
  MqttPublicationTopic get topic => _topic;
}

/// Auto reconnect event
class MqttAutoReconnect {
  /// Constructor
  MqttAutoReconnect({userReconnect = false}) {
    userRequested = userReconnect;
  }

  /// If set auto reconnect has been invoked through the client
  /// [doAutoReconnect] method, i.e. a user request.
  var userRequested;
}
