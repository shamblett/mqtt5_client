// ignore_for_file: prefer-match-file-name

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt5_client.dart';

/// The message available event.
class MqttMessageAvailable {
  /// The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;

  /// Constructor
  MqttMessageAvailable(this._message);
}

/// The connect acknowledge message available event raised by the Connection class
class MqttConnectAckMessageAvailable {
  /// The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;

  /// Constructor
  MqttConnectAckMessageAvailable(this._message);
}

/// Message received for publishing event.
class MqttMessageReceived {
  // The message associated with the event
  final MqttMessage _message;

  // The topic
  final MqttPublicationTopic _topic;

  /// Message
  MqttMessage get message => _message;

  /// Topic
  MqttPublicationTopic get topic => _topic;

  /// Constructor
  MqttMessageReceived(this._topic, this._message);
}

/// Auto reconnect event
class MqttAutoReconnect {
  /// If set auto reconnect has been invoked through the client
  /// [doAutoReconnect] method, i.e. a user request.
  bool userRequested = false;

  /// True if the previous state was connected
  bool wasConnected = false;

  /// Constructor
  MqttAutoReconnect({this.userRequested = false, this.wasConnected = false});
}

/// Re subscribe event
class MqttResubscribe {
  /// If set re subscribe has been triggered from auto reconnect.
  bool fromAutoReconnect = false;

  /// Constructor
  MqttResubscribe({this.fromAutoReconnect = false});
}

/// Disconnect on keep alive on no ping response event
class DisconnectOnNoPingResponse {
  /// Constructor
  DisconnectOnNoPingResponse();
}

/// Disconnect on sent message failed event
class DisconnectOnNoMessageSent {
  /// Constructor
  DisconnectOnNoMessageSent();
}
