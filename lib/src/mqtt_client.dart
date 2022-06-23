/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The client disconnect callback type
typedef DisconnectCallback = void Function();

/// The client Connect callback type
typedef ConnectCallback = void Function();

/// The client auto reconnect callback type
typedef AutoReconnectCallback = void Function();

/// The client auto reconnect complete callback type
typedef AutoReconnectCompleteCallback = void Function();

/// A client class for interacting with MQTT Data Packets.
/// Do not instantiate this class directly, instead instantiate
/// either a [MqttClientServer] class or an [MqttBrowserClient] as needed.
/// This class now provides common functionality between server side
/// and web based clients.
class MqttClient {
  /// Initializes a new instance of the MqttClient class using the
  /// default Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  MqttClient(this.server, this.clientIdentifier) {
    port = MqttConstants.defaultMqttPort;
  }

  /// Initializes a new instance of the MqttClient class using
  /// the supplied Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  /// The port to use
  MqttClient.withPort(this.server, this.clientIdentifier, this.port);

  /// Server name
  String server;

  /// Port number
  int? port;

  /// Client identifier
  String clientIdentifier;

  /// Incorrect instantiation protection
  @protected
  var instantiationCorrect = false;

  /// Auto reconnect, the client will auto reconnect if set true.
  ///
  /// The auto reconnect mechanism will not be invoked either for a client
  /// that has not been connected, i.e. you must have established an initial
  /// connection to the broker or for a solicited disconnect request.
  ///
  /// Once invoked the mechanism will try forever to reconnect to the broker with its
  /// original connection parameters. This can be stopped only by calling
  /// [disconnect()] on the client.
  bool autoReconnect = false;

  /// Re subscribe on auto reconnect.
  /// Auto reconnect will perform automatic re subscription of existing confirmed subscriptions
  /// unless this is set to false.
  /// In this case the caller must perform their own re subscriptions manually using [unsubscribe],
  /// [subscribe] and [resubscribe] as needed from the appropriate callbacks.
  bool resubscribeOnAutoReconnect = true;

  /// The Handler that is managing the connection to the remote server.
  @protected
  dynamic connectionHandler;

  @protected
  List<String>? websocketProtocolString;

  /// User definable websocket protocols. Use this for non default websocket
  /// protocols only if your broker needs this. There are two defaults in
  /// MqttWsConnection class, the multiple protocol is the default. Some brokers
  /// will not accept a list and only expect a single protocol identifier,
  /// in this case use the single protocol default. You can supply your own
  /// list, or to disable this entirely set the protocols to an
  /// empty list , i.e [].
  set websocketProtocols(List<String> protocols) {
    websocketProtocolString = protocols;
    if (connectionHandler != null) {
      connectionHandler.websocketProtocols = protocols;
    }
  }

  /// The subscriptions manager responsible for tracking subscriptions.
  @protected
  MqttSubscriptionManager? subscriptionsManager;

  /// Handles the connection management while idle.
  @protected
  MqttConnectionKeepAlive? keepAlive;

  /// Keep alive period, seconds
  int keepAlivePeriod = MqttConstants.defaultKeepAlive;

  /// Handles everything to do with publication management.
  @protected
  MqttPublishingManager? publishingManager;

  /// Published message stream. A publish message is added to this
  /// stream on completion of the message publishing protocol for a Qos level.
  /// Attach listeners only after connect has been called.
  Stream<MqttPublishMessage>? get published =>
      publishingManager != null ? publishingManager!.published.stream : null;

  /// Handles everything to do with authentication messages.
  @protected
  MqttAuthenticationManager? authenticationManager =
      MqttAuthenticationManager();

  /// Authenticate message stream. A received authenticate message is
  /// added to this stream.
  /// Attach listeners only after connect has been called.
  Stream<MqttAuthenticateMessage>? get authentication =>
      authenticationManager != null
          ? authenticationManager!.authenticated.stream
          : null;

  /// Gets the current connection state of the Mqtt Client.
  /// Will be removed, use connectionStatus
  @Deprecated('Use ConnectionStatus, not this')
  MqttConnectionState? get connectionState => connectionHandler != null
      ? connectionHandler.connectionStatus.state
      : MqttConnectionState.disconnected;

  final MqttConnectionStatus _connectionStatus = MqttConnectionStatus();

  /// Gets the current connection status of the Mqtt Client.
  /// This is the connection state as above also with the broker return code.
  /// Set after every connection attempt.
  MqttConnectionStatus? get connectionStatus => connectionHandler != null
      ? connectionHandler.connectionStatus
      : _connectionStatus;

  /// The connection message to use to override the default
  MqttConnectMessage? connectionMessage;

  /// Client disconnect callback, called on unsolicited disconnect.
  /// This will not be called even if set if [autoReconnect} is set,instead
  /// [AutoReconnectCallback] will be called.
  DisconnectCallback? onDisconnected;

  /// Client connect callback, called on successful connect
  ConnectCallback? onConnected;

  /// Auto reconnect callback, if auto reconnect is selected this callback will
  /// be called before auto reconnect processing is invoked to allow the user to
  /// perform any pre auto reconnect actions.
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback, if auto reconnect is selected this callback will
  /// be called after auto reconnect processing is completed to allow the user to
  /// perform any post auto reconnect actions.
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Subscribed callback, function returns a void and takes a
  /// string parameter, the topic that has been subscribed to.
  SubscribeCallback? _onSubscribed;

  /// On subscribed
  SubscribeCallback? get onSubscribed => _onSubscribed;

  set onSubscribed(SubscribeCallback? cb) {
    _onSubscribed = cb;
    subscriptionsManager?.onSubscribed = cb;
  }

  /// Subscribed failed callback, function returns a void and takes a
  /// string parameter, the topic that has failed subscription.
  /// Invoked either by subscribe if an invalid topic is supplied or on
  /// reception of a failed subscribe indication from the broker.
  SubscribeFailCallback? _onSubscribeFail;

  /// On subscribed fail
  SubscribeFailCallback? get onSubscribeFail => _onSubscribeFail;

  set onSubscribeFail(SubscribeFailCallback? cb) {
    _onSubscribeFail = cb;
    subscriptionsManager?.onSubscribeFail = cb;
  }

  /// Unsubscribed callback, function returns a void and takes a
  /// string parameter, the topic that has been unsubscribed.
  UnsubscribeCallback? _onUnsubscribed;

  /// On unsubscribed
  UnsubscribeCallback? get onUnsubscribed => _onUnsubscribed;

  set onUnsubscribed(UnsubscribeCallback? cb) {
    _onUnsubscribed = cb;
    subscriptionsManager?.onUnsubscribed = cb;
  }

  /// Ping response received callback.
  /// If set when a ping response is received from the broker
  /// this will be called.
  /// Can be used for health monitoring outside of the client itself.
  PongCallback? _pongCallback;

  /// The ping received callback
  PongCallback? get pongCallback => _pongCallback;

  set pongCallback(PongCallback? cb) {
    _pongCallback = cb;
    keepAlive?.pongCallback = cb;
  }

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// The stream on which all subscribed topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage>>> get updates =>
      subscriptionsManager!.subscriptionNotifier;

  /// Comon client connection method.
  Future<MqttConnectionStatus?> connect(
      [String? username, String? password]) async {
    // Protect against an incorrect instantiation
    if (!instantiationCorrect) {
      throw MqttIncorrectInstantiationException();
    }
    checkCredentials(username, password);
    // Set the authentication parameters in the connection
    // message if we have one.
    connectionMessage?.authenticateAs(username, password);

    // Do the connection
    if (websocketProtocolString != null) {
      connectionHandler.websocketProtocols = websocketProtocolString;
    }
    connectionHandler.onDisconnected = internalDisconnect;
    connectionHandler.onConnected = onConnected;
    connectionHandler.onAutoReconnect = onAutoReconnect;
    connectionHandler.onAutoReconnected = onAutoReconnected;
    publishingManager =
        MqttPublishingManager(connectionHandler, clientEventBus);
    authenticationManager ??= MqttAuthenticationManager();
    authenticationManager!.connectionHandler = connectionHandler;
    subscriptionsManager =
        MqttSubscriptionManager(connectionHandler, clientEventBus);
    subscriptionsManager!.onSubscribed = onSubscribed;
    subscriptionsManager!.onUnsubscribed = onUnsubscribed;
    subscriptionsManager!.onSubscribeFail = onSubscribeFail;
    subscriptionsManager!.resubscribeOnAutoReconnect =
        resubscribeOnAutoReconnect;
    keepAlive = MqttConnectionKeepAlive(connectionHandler, keepAlivePeriod);
    if (pongCallback != null) {
      keepAlive!.pongCallback = pongCallback;
    }
    final connectMessage = getConnectMessage(username, password);
    // If the client id is not set in the connection message use the one
    // supplied in the constructor.
    if (connectMessage.payload.clientIdentifier.isEmpty) {
      connectMessage.payload.clientIdentifier = clientIdentifier;
    }
    connectionMessage = connectMessage;
    return connectionHandler.connect(server, port, connectMessage);
  }

  ///  Gets a pre-configured connect message if one has not been
  ///  supplied by the user.
  ///  Returns an MqttConnectMessage that can be used to connect to a
  ///  message broker if the user has not set one.
  MqttConnectMessage getConnectMessage(String? username, String? password) =>
      connectionMessage ??= MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          // Explicitly set the will flag
          .withWillQos(MqttQos.atMostOnce)
          .keepAliveFor(MqttConstants.defaultKeepAlive)
          .authenticateAs(username, password)
          .startClean();

  /// Auto reconnect method, used to invoke a manual auto reconnect sequence.
  /// If [autoReconnect] is not set this method does nothing.
  /// If the client is not disconnected this method will have no effect
  /// unless the [force] parameter is set to true, otherwise
  /// auto reconnect will try indefinitely to reconnect to the broker.
  void doAutoReconnect({bool force = false}) {
    if (!autoReconnect) {
      MqttLogger.log(
          'MqttClient::doAutoReconnect - auto reconnect is not set, exiting');
      return;
    }

    if (connectionStatus!.state != MqttConnectionState.connected || force) {
      final wasConnected =
          connectionStatus!.state == MqttConnectionState.connected;
      clientEventBus!.fire(
          MqttAutoReconnect(userRequested: true, wasConnected: wasConnected));
    }
  }

  /// Initiates a topic subscription request to the connected broker
  /// with a strongly typed data processor callback.
  /// The topic to subscribe to.
  /// The maximum Qos level.
  /// Returns the subscription or null on failure
  MqttSubscription? subscribe(String topic, MqttQos qosLevel) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw MqttConnectionException(connectionHandler?.connectionStatus?.state);
    }
    return subscriptionsManager!.subscribeSubscriptionTopic(topic, qosLevel);
  }

  /// Initiates a topic subscription request to the connected broker
  /// with a strongly typed data processor callback.
  /// The subscription to subscribe to.
  /// Returns the subscription or null on failure
  MqttSubscription? subscribeWithSubscription(MqttSubscription subscription) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw MqttConnectionException(connectionHandler?.connectionStatus?.state);
    }
    return subscriptionsManager!.subscribeSubscription(subscription);
  }

  /// Initiates a topic subscription request to the connected broker
  /// with a strongly typed data processor callback.
  /// The list of subscriptions to subscribe to.
  /// Note that user properties are set on a per message basis not a per
  /// subscription basis, if you wish to send user properties then set
  /// them on the first subscription in the list.
  /// Returns the subscriptions or null on failure
  List<MqttSubscription>? subscribeWithSubscriptionList(
      List<MqttSubscription> subscriptions) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw MqttConnectionException(connectionHandler?.connectionStatus?.state);
    }
    return subscriptionsManager!.subscribeSubscriptionList(subscriptions);
  }

  /// Re subscribe.
  /// Unsubscribes all confirmed subscriptions and re subscribes them
  /// without sending unsubscribe messages to the broker.
  /// If an unsubscribe message to the broker is needed then use
  /// [unsubscribe] followed by [subscribe] for each subscription.
  /// Can be used in auto reconnect processing to force manual re subscription of all existing
  /// confirmed subscriptions.
  void resubscribe() => subscriptionsManager!.resubscribe();

  /// Publishes a message to the message broker.
  /// Returns the message identifer assigned to the message.
  /// Raises InvalidTopicException if the topic supplied violates the
  /// MQTT topic format rules.
  int publishMessage(
      String topic, MqttQos qualityOfService, typed.Uint8Buffer data,
      {bool retain = false, List<MqttUserProperty>? userProperties}) {
    if (connectionHandler?.connectionStatus?.state !=
        MqttConnectionState.connected) {
      throw MqttConnectionException(connectionHandler?.connectionStatus?.state);
    }
    try {
      final pubTopic = MqttPublicationTopic(topic);
      return publishingManager!.publish(pubTopic, qualityOfService, data,
          retain: retain, userProperties: userProperties);
    } on Exception catch (e) {
      throw MqttInvalidTopicException(e.toString(), topic);
    }
  }

  /// Publishes a user supplied publish message to the message broker.
  /// This allows the user to custom build the publish message as is needed.
  /// The user is responsible for the integrity of the publishing message.
  /// Returns the message identifier assigned to the message. Note that
  /// any supplied message identifier will be overridden by this method.
  int publishUserMessage(MqttPublishMessage message) =>
      publishingManager!.publishUserMessage(message);

  /// Unsubscribe from a topic.
  void unsubscribeStringTopic(String topic) {
    subscriptionsManager!.unsubscribeTopic(topic);
  }

  /// Unsubscribe from a subscription.
  void unsubscribeSubscription(MqttSubscription subscription) {
    subscriptionsManager!.unsubscribeSubscription(subscription);
  }

  /// Unsubscribe from a subscription list.
  /// Note that user properties are set on a per message basis not a per
  /// subscription basis, if you wish to send user properties then set
  /// them on the first subscription in the list.
  void unsubscribeSubscriptionList(List<MqttSubscription> subscriptions) {
    subscriptionsManager!.unsubscribeSubscriptionList(subscriptions);
  }

  /// Gets the current status of a subscription topic.
  MqttSubscriptionStatus getSubscriptionTopicStatus(String topic) =>
      subscriptionsManager!.getSubscriptionTopicStatus(topic);

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionStatus(MqttSubscription subscription) =>
      subscriptionsManager!.getSubscriptionStatus(subscription);

  /// Disconnect from the broker.
  ///
  /// This is a hard disconnect, a disconnect message is sent to the
  /// broker and the client is then reset to its pre-connection state,
  /// i.e all subscriptions are deleted, on subsequent reconnection the
  /// use must re-subscribe, also the updates change notifier is re-initialised
  /// and as such the user must re-listen on this stream.
  ///
  /// Do NOT call this in any onDisconnect callback that may be set,
  /// this will result in a loop situation.
  ///
  /// This method will disconnect regardles of the [autoReconnect] state.
  void disconnect() {
    _disconnect(unsolicited: false);
  }

  /// Re-authenticate.
  ///
  /// Sends the supplied authentication message and waits for the a response from the broker.
  /// Use this if you wish to re-authenticate without listening for authenticate messages.
  /// This method will wait a default 30 seconds unless another timeout value is specified.
  ///
  /// If the re-authenticate times out an authenticate message is returned with the timeout
  /// indicator set.
  Future<MqttAuthenticateMessage> reauthenticate(MqttAuthenticateMessage msg,
      {int waitTimeInSeconds = 30}) {
    return authenticationManager!
        .reauthenticate(msg, waitTimeInSeconds: waitTimeInSeconds);
  }

  /// Send an authenticate message to the broker.
  void sendAuthenticate(MqttAuthenticateMessage message) {
    authenticationManager!.send(message);
  }

  /// Internal disconnect.
  ///
  /// This is always passed to the connection handler to allow the
  /// client to close itself down correctly on disconnect.
  @protected
  void internalDisconnect() {
    if (connectionHandler == null) {
      MqttLogger.log(
          'MqttClient::internalDisconnect - not invoking disconnect, no connection handler');
      return;
    }
    if (autoReconnect && connectionHandler.initialConnectionComplete) {
      if (!connectionHandler.autoReconnectInProgress) {
        // Fire an automatic auto reconnect request
        clientEventBus!.fire(MqttAutoReconnect(userRequested: false));
      } else {
        MqttLogger.log(
            'MqttClient::internalDisconnect - not invoking auto connect, already in progress');
      }
    } else {
      // Unsolicited disconnect
      if (connectionHandler.initialConnectionComplete) {
        _disconnect(unsolicited: true);
      }
    }
  }

  /// Actual disconnect processing
  void _disconnect({bool unsolicited = true}) {
    // Only disconnect the connection handler if the request is
    // solicited, unsolicited requests, ie broker termination don't
    // need this.
    var disconnectOrigin = MqttDisconnectionOrigin.unsolicited;
    if (!unsolicited) {
      connectionHandler?.disconnect();
      disconnectOrigin = MqttDisconnectionOrigin.solicited;
    }
    publishingManager?.published.close();
    publishingManager = null;
    authenticationManager?.authenticated.close();
    authenticationManager = null;
    subscriptionsManager = null;
    keepAlive?.stop();
    keepAlive = null;
    _connectionStatus.reasonCode = connectionStatus?.reasonCode;
    _connectionStatus.reasonString = connectionStatus?.reasonString;
    connectionHandler = null;
    clientEventBus?.destroy();
    clientEventBus = null;
    // Set the connection status before calling onDisconnected
    _connectionStatus.state = MqttConnectionState.disconnected;
    _connectionStatus.disconnectionOrigin = disconnectOrigin;
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }

  /// Check the username and password validity
  @protected
  void checkCredentials(String? username, String? password) {
    if (username != null) {
      MqttLogger.log("Authenticating with username '{$username}' "
          "and password '{$password}'");
      if (username.trim().length >
          MqttConstants.recommendedMaxUsernamePasswordLength) {
        MqttLogger.log(
            'MqttClient::checkCredentials - Username length (${username.trim().length}) '
            'exceeds the max recommended in the MQTT spec. ');
      }
    }
    if (password != null &&
        password.trim().length >
            MqttConstants.recommendedMaxUsernamePasswordLength) {
      MqttLogger.log(
          'MqttClient::checkCredentials - Password length (${password.trim().length}) '
          'exceeds the max recommended in the MQTT spec. ');
    }
  }

  /// Turn on logging, true to start, false to stop
  void logging({required bool on}) {
    MqttLogger.loggingOn = false;
    if (on) {
      MqttLogger.loggingOn = true;
    }
  }
}
