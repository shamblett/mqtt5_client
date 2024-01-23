/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// An Mqtt message that is used to initiate a connection to a message broker.
/// After a network connection is established by a client to a broker, the
/// first message sent from the client to the broker MUST be a connect
/// message.
///
/// A client can only send the connect message once over a network connection.
///
/// Various fields are used in the construction of this message, for more details on
/// the meaning of these fields please refer to the classes in which they are defined,
/// specifically [MqttConnectFlags], [MqttConnectPayload], [MqttConnectVariableHeader]
/// and [MqttWillProperties].
///
/// In particular if using a will message refer to the [MqttWillProperties] class for details
/// of the options in this area.
class MqttConnectMessage extends MqttMessage {
  /// Initializes a new instance of the MqttConnectMessage class.
  MqttConnectMessage() {
    header = MqttHeader().asType(MqttMessageType.connect);
    _variableHeader = MqttConnectVariableHeader();
    payload = MqttConnectPayload(_variableHeader);
  }

  MqttConnectVariableHeader? _variableHeader;

  /// The variable header contents.
  /// Contains extended metadata about the message.
  MqttConnectVariableHeader? get variableHeader => _variableHeader;

  /// The payload of the message.
  late MqttConnectPayload payload;

  /// Sets the clean start flag to clear any persistent session for the client.
  /// Mutually exclusive with [startSession]the last method applied to the message will take
  /// effect.
  MqttConnectMessage startClean() {
    _variableHeader!.connectFlags.cleanStart = true;
    return this;
  }

  /// Starts a persistent session with the broker.
  /// The [sessionExpiryInterval] can be any none zero value up to the the maximum
  /// [MqttConnectVariableHeader.sessionDoesNotExpire].
  /// If 0 is passed the maximum value is used.
  /// Mutually exclusive with [startClean], the last method applied to the message will take
  /// effect.
  MqttConnectMessage startSession(
      {int sessionExpiryInterval =
          MqttConnectVariableHeader.sessionDoesNotExpire}) {
    final interval = sessionExpiryInterval == 0
        ? MqttConnectVariableHeader.sessionDoesNotExpire
        : sessionExpiryInterval;
    _variableHeader!.sessionExpiryInterval = interval;
    _variableHeader!.connectFlags.cleanStart = false;
    return this;
  }

  /// Sets the keep alive period
  MqttConnectMessage keepAliveFor(int keepAliveSeconds) {
    _variableHeader!.keepAlive = keepAliveSeconds;
    return this;
  }

  /// Sets the Will flag.
  ///
  /// Note that setting this will also activate encoding of will
  /// properties and other dependant fields.
  /// Refer to the [MqttWillProperties] class for details.
  MqttConnectMessage will() {
    _variableHeader!.connectFlags.willFlag = true;
    return this;
  }

  /// Sets the Will Qos.
  MqttConnectMessage withWillQos(MqttQos qos) {
    _variableHeader!.connectFlags.willQos = qos;
    return this;
  }

  /// Sets the Will retain flag.
  MqttConnectMessage withWillRetain() {
    _variableHeader!.connectFlags.willRetain = true;
    return this;
  }

  /// Sets the client identifier of the message.
  MqttConnectMessage withClientIdentifier(String clientIdentifier) {
    payload.clientIdentifier = clientIdentifier;
    return this;
  }

  /// Sets the will payload.
  MqttConnectMessage withWillPayload(typed.Uint8Buffer willPayload) {
    payload.willPayload = willPayload;
    return this;
  }

  /// Sets the Will topic.
  MqttConnectMessage withWillTopic(String willTopic) {
    payload.willTopic = willTopic;
    return this;
  }

  /// Sets the will properties
  MqttConnectMessage withWillProperties(MqttWillProperties properties) {
    payload.willProperties = properties;
    return this;
  }

  /// Sets the message payload
  MqttConnectMessage withPayload(MqttConnectPayload payload) {
    this.payload = payload;
    return this;
  }

  /// Sets a list of user properties
  MqttConnectMessage withUserProperties(List<MqttUserProperty> properties) {
    _variableHeader!.userProperty = properties;
    return this;
  }

  /// Add a specific user property
  void addUserProperty(MqttUserProperty property) {
    _variableHeader!.userProperty = [property];
  }

  /// Add a user property from the supplied name/value pair
  void addUserPropertyPair(String name, String value) {
    final property = MqttUserProperty();
    property.pairName = name;
    property.pairValue = value;
    addUserProperty(property);
  }

  /// Sets the session expiry interval.
  MqttConnectMessage withSessionExpiryInterval(int interval) {
    _variableHeader!.sessionExpiryInterval = interval;
    return this;
  }

  /// Sets the receive maximum.
  MqttConnectMessage withReceiveMaximum(int maximum) {
    _variableHeader!.receiveMaximum = maximum;
    return this;
  }

  /// Sets the maximum message size.
  MqttConnectMessage withMaximumMessageSize(int maximum) {
    _variableHeader!.maximumPacketSize = maximum;
    return this;
  }

  /// Sets the topic alias maximum.
  MqttConnectMessage withTopicAliasMaximum(int maximum) {
    _variableHeader!.topicAliasMaximum = maximum;
    return this;
  }

  /// Sets the request response information flag.
  MqttConnectMessage withRequestResponseInformation(bool information) {
    _variableHeader!.requestResponseInformation = information;
    return this;
  }

  /// Sets the request problem information flag.
  MqttConnectMessage withRequestProblemInformation(bool information) {
    _variableHeader!.requestProblemInformation = information;
    return this;
  }

  /// Sets the authentication method.
  MqttConnectMessage withAuthenticationMethod(String method) {
    _variableHeader!.authenticationMethod = method;
    return this;
  }

  /// Sets the authentication data
  MqttConnectMessage withAuthenticationData(typed.Uint8Buffer data) {
    _variableHeader!.authenticationData = data;
    return this;
  }

  /// Indicates if an authentication method is set
  bool get authenticationRequested =>
      variableHeader!.authenticationMethod.isNotEmpty;

  /// Sets the authentication details
  MqttConnectMessage authenticateAs(String? username, String? password) {
    if (username != null) {
      _variableHeader!.connectFlags.usernameFlag = username.isNotEmpty;
      payload.username = username;
    }
    if (password != null) {
      _variableHeader!.connectFlags.passwordFlag = password.isNotEmpty;
      payload.password = password;
    }
    return this;
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(
        _variableHeader!.getWriteLength() + payload.getWriteLength(),
        messageStream);
    _variableHeader!.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.write(_variableHeader.toString());
    sb.write(payload.toString());
    return sb.toString();
  }
}
