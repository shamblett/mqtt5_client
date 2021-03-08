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
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;
}

/// The connect acknowledge message available event raised by the Connection class
class MqttConnectAckMessageAvailable {
  /// Constructor
  MqttConnectAckMessageAvailable(this._message);

  /// The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;
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
  MqttAutoReconnect({this.userRequested = false, this.wasConnected = false});

  /// If set auto reconnect has been invoked through the client
  /// [doAutoReconnect] method, i.e. a user request.
  bool userRequested = false;

  /// True if the previous state was connected
  bool wasConnected = false;
}

/// Re subscribe event
class MqttResubscribe {
  /// Constructor
  MqttResubscribe({this.fromAutoReconnect = false});

  /// If set re subscribe has been triggered from auto reconnect.
  bool fromAutoReconnect = false;
}
