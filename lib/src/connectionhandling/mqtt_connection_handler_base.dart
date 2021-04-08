/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

///  This class provides shared connection functionality
///  to serverand browser connection handler implementations.
abstract class MqttConnectionHandlerBase implements MqttIConnectionHandler {
  /// Initializes a new instance of the [MqttConnectionHandlerBase] class.
  MqttConnectionHandlerBase(this.clientEventBus,
      {required this.maxConnectionAttempts});

  /// Successful connection callback.
  @override
  ConnectCallback? onConnected;

  /// Unsolicited disconnection callback.
  @override
  DisconnectCallback? onDisconnected;

  /// Auto reconnect callback
  @override
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback
  @override
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Auto reconnect in progress
  @override
  bool? autoReconnectInProgress = false;

  // Server name, needed for auto reconnect.
  @override
  String? server;

  // Port number, needed for auto reconnect.
  @override
  int? port;

  // Connection message, needed for auto reconnect.
  @override
  MqttConnectMessage? connectionMessage;

  /// Callback function to handle bad certificate. if true, ignore the error.
  @override
  bool Function(dynamic certificate)? onBadCertificate;

  /// Max connection attempts
  final int? maxConnectionAttempts;

  /// The broker connection acknowledgment timer
  @protected
  late MqttCancellableAsyncSleep connectTimer;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// User supplied websocket protocols
  @protected
  List<String>? websocketProtocols;

  /// The connection
  @protected
  late dynamic connection;

  /// Indicates if the connect message has an authentication method
  /// i.e. authentication has been requested.
  @override
  bool? authenticationRequested = false;

  /// Registry of message processors
  @protected
  Map<MqttMessageType, MessageCallbackFunction?> messageProcessorRegistry =
      <MqttMessageType, MessageCallbackFunction?>{};

  /// Registry of sent message callbacks
  @protected
  List<MessageCallbackFunction> sentMessageCallbacks =
      <MessageCallbackFunction>[];

  /// We have had an initial connection
  @protected
  bool initialConnectionComplete = false;

  /// Connection status
  @override
  MqttConnectionStatus connectionStatus = MqttConnectionStatus();

  /// Connect to the specific Mqtt Connection.
  @override
  Future<MqttConnectionStatus> connect(
      String? server, int? port, MqttConnectMessage? message) async {
    // Save the parameters for auto reconnect.
    this.server = server;
    this.port = port;
    MqttLogger.log(
        'MqttConnectionHandlerBase::connect - server $server, port $port');
    // ignore: unnecessary_this
    // ignore: unnecessary_this
    this.connectionMessage = message;
    try {
      await internalConnect(server, port, message);
      return connectionStatus;
    } on Exception {
      connectionStatus.state = MqttConnectionState.faulted;
      rethrow;
    }
  }

  /// Connect to the specific Mqtt Connection internally.
  @protected
  Future<MqttConnectionStatus> internalConnect(
      String? hostname, int? port, MqttConnectMessage? message);

  /// Auto reconnect
  @protected
  void autoReconnect(MqttAutoReconnect reconnectEvent) async {
    MqttLogger.log('MqttConnectionHandlerBase::autoReconnect entered');
    // If already in progress exit and we were not connected return
    if (autoReconnectInProgress! && !reconnectEvent.wasConnected) {
      return;
    }
    autoReconnectInProgress = true;
    // If the auto reconnect callback is set call it
    if (onAutoReconnect != null) {
      onAutoReconnect!();
    }

    // If we are connected disconnect from the broker.
    if (reconnectEvent.wasConnected) {
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - was connected, sending disconnect');
      sendMessage(MqttDisconnectMessage()
          .withReasonCode(MqttDisconnectReasonCode.normalDisconnection));
      connectionStatus.state = MqttConnectionState.disconnecting;
    }
    connection.disconnect(auto: true);
    connection.onDisconnected = null;
    MqttLogger.log(
        'MqttConnectionHandlerBase::autoReconnect - attempting reconnection');
    connectionStatus = await connect(server, port, connectionMessage);
    autoReconnectInProgress = false;
    if (connectionStatus.state == MqttConnectionState.connected) {
      connection.onDisconnected = onDisconnected;
      // Fire the re subscribe event.
      clientEventBus!.fire(MqttResubscribe(fromAutoReconnect: true));
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - auto reconnect complete');
      // If the auto reconnect callback is set call it
      if (onAutoReconnected != null) {
        onAutoReconnected!();
      }
    } else {
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - auto reconnect failed - re trying');
      clientEventBus!.fire(MqttAutoReconnect());
    }
  }

  /// Sends a message to the broker through the current connection.
  @override
  void sendMessage(MqttMessage message) {
    MqttLogger.log(
        'MqttConnectionHandlerBase::sendMessage - sending message started >>> -> ',
        message);
    // Check for validity
    if (!message.isValid) {
      throw ArgumentError(
          'MqttConnectionHandlerBase::sendMessage - message cannot be sent, not valid');
    }
    if ((connectionStatus.state == MqttConnectionState.connected) ||
        (connectionStatus.state == MqttConnectionState.connecting)) {
      final buff = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buff);
      message.writeTo(stream);
      stream.seek(0);
      connection.send(stream);
      // Let any registered people know we're doing a message.
      for (final callback in sentMessageCallbacks) {
        callback(message);
      }
    } else {
      MqttLogger.log('MqttConnectionHandler::sendMessage - not connected');
    }
    MqttLogger.log(
        'MqttConnectionHandlerBase::sendMessage - sending message ended >>>');
  }

  /// Closes the connection to the Mqtt message broker.
  @override
  void close() {
    if (connectionStatus.state == MqttConnectionState.connected) {
      disconnect();
    }
  }

  /// Registers for the receipt of messages when they arrive.
  @override
  void registerForMessage(
      MqttMessageType msgType, MessageCallbackFunction callback) {
    messageProcessorRegistry[msgType] = callback;
  }

  /// UnRegisters for the receipt of messages when they arrive.
  @override
  void unRegisterForMessage(MqttMessageType msgType) {
    messageProcessorRegistry.remove(msgType);
  }

  /// Registers a callback to be called whenever a message is sent.
  @override
  void registerForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.add(sentMsgCallback);
  }

  /// UnRegisters a callback that is called whenever a message is sent.
  @override
  void unRegisterForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.remove(sentMsgCallback);
  }

  /// Handles the Message Available event of the connection control for
  /// handling non connection messages.
  @protected
  void messageAvailable(MqttMessageAvailable event) {
    final messageType = event.message!.header!.messageType;
    MqttLogger.log(
        'MqttConnectionHandlerBase::messageAvailable - message type is $messageType');
    final callback = messageProcessorRegistry[messageType!];
    if (callback != null) {
      callback(event.message!);
    } else {
      MqttLogger.log(
          'MqttConnectionHandlerBase::messageAvailable - WARN - no registered callback for this message type');
    }
  }

  /// Disconnects
  @override
  MqttConnectionState disconnect() {
    MqttLogger.log('MqttConnectionHandlerBase::disconnect');
    if (connectionStatus.state == MqttConnectionState.connected) {
      // Send a disconnect message to the broker
      sendMessage(MqttDisconnectMessage()
          .withReasonCode(MqttDisconnectReasonCode.normalDisconnection));
    }
    // Disconnect
    _performConnectionDisconnect();
    return connectionStatus.state;
  }

  /// Disconnects the underlying connection object.
  @protected
  void _performConnectionDisconnect() {
    MqttLogger.log(
        'MqttConnectionHandlerBase::_performConnectionDisconnect entered');
    connectionStatus.state = MqttConnectionState.disconnected;
  }

  /// Processes the connect acknowledgement message.
  @protected
  bool connectAckProcessor(MqttMessage msg) {
    MqttLogger.log('MqttConnectionHandlerBase::_connectAckProcessor');
    try {
      final ackMsg = msg as MqttConnectAckMessage;
      // Drop the connection if our connect request has been rejected.
      if (MqttReasonCodeUtilities.isError(
          mqttConnectReasonCode.asInt(ackMsg.variableHeader!.reasonCode)!)) {
        MqttLogger.log('MqttConnectionHandlerBase::_connectAckProcessor '
            'connection rejected, reason code is ${mqttConnectReasonCode.asString(ackMsg.variableHeader!.reasonCode)}');
        connectionStatus.reasonCode = ackMsg.variableHeader!.reasonCode;
        connectionStatus.reasonString = ackMsg.variableHeader!.reasonString;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log('MqttConnectionHandlerBase::_connectAckProcessor '
            '- state = connected');
        connectionStatus.state = MqttConnectionState.connected;
        connectionStatus.reasonCode = ackMsg.variableHeader!.reasonCode;
        connectionStatus.reasonString = ackMsg.variableHeader!.reasonString;
        connectionStatus.connectAckMessage = msg;
        // Call the connected callback if we have one
        if (onConnected != null) {
          onConnected!();
        }
      }
    } on Exception {
      _performConnectionDisconnect();
    }
    // Cancel the connect timer;
    MqttLogger.log('MqttConnectionHandlerBase:: cancelling connect timer');
    connectTimer.cancel();
    return true;
  }

  /// Connect acknowledge recieved
  void connectAckReceived(MqttConnectAckMessageAvailable event) {
    connectAckProcessor(event.message!);
  }

  /// Initialise the event listeners;
  void initialiseListeners() {
    clientEventBus!.on<MqttAutoReconnect>().listen(autoReconnect);
    clientEventBus!.on<MqttMessageAvailable>().listen(messageAvailable);
    clientEventBus!
        .on<MqttConnectAckMessageAvailable>()
        .listen(connectAckReceived);
  }
}
