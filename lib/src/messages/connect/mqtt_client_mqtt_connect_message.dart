/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// An Mqtt message that is used to initiate a connection to a message broker.
/// After a Network Connection is established by a Client to a Server, the
/// first packet sent from the Client to the Server MUST be a CONNECT
/// packet.
///
/// A Client can only send the CONNECT packet once over a Network Connection.
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
    variableHeader = MqttConnectVariableHeader();
    payload = MqttConnectPayload(variableHeader);
  }

  /// The variable header contents.
  /// Contains extended metadata about the message
  MqttConnectVariableHeader variableHeader;

  /// The payload of the Mqtt Message.
  MqttConnectPayload payload;

  /// Sets the startClean flag so that the broker drops any messages
  /// that were previously destined for us.
  MqttConnectMessage startClean() {
    variableHeader.connectFlags.cleanStart = true;
    return this;
  }

  /// Sets the keep alive period
  MqttConnectMessage keepAliveFor(int keepAliveSeconds) {
    variableHeader.keepAlive = keepAliveSeconds;
    return this;
  }

  /// Sets the Will flag of the variable header.
  /// Note that setting this will also activate encoding of will
  /// properties and other dependant fields.
  MqttConnectMessage will() {
    variableHeader.connectFlags.willFlag = true;
    return this;
  }

  /// Sets the WillQos of the connect flag.
  MqttConnectMessage withWillQos(MqttQos qos) {
    variableHeader.connectFlags.willQos = qos;
    return this;
  }

  /// Sets the WillRetain flag of the Connection Flags
  MqttConnectMessage withWillRetain() {
    variableHeader.connectFlags.willRetain = true;
    return this;
  }

  /// Sets the client identifier of the message.
  MqttConnectMessage withClientIdentifier(String clientIdentifier) {
    payload.clientIdentifier = clientIdentifier;
    return this;
  }

  /// Sets the will payload
  /// Automatically sets the will flag
  MqttConnectMessage withWillPayload(typed.Uint8Buffer willPayload) {
    will();
    payload.willPayload = willPayload;
    return this;
  }

  /// Sets the Will Topic
  /// Automatically sets the will flag
  MqttConnectMessage withWillTopic(String willTopic) {
    will();
    payload.willTopic = willTopic;
    return this;
  }

  /// Sets the will properties
  /// Automatically sets the will flag
  MqttConnectMessage withWillProperties(MqttWillProperties properties) {
    payload.willProperties = properties;
    if (properties != null) {
      will();
    }
    return this;
  }

  /// Sets the payload
  MqttConnectMessage withPayload(MqttConnectPayload payload) {
    this.payload = payload;
    return this;
  }

  /// Sets a list of user properties
  MqttConnectMessage withUserProperties(
      List<MqttStringPairProperty> properties) {
    variableHeader.userProperties = properties;
    return this;
  }

  /// Add a specific user property
  MqttConnectMessage withUserProperty(MqttStringPairProperty property) {
    variableHeader.userProperties = [property];
    return this;
  }

  /// Sets the authentication
  MqttConnectMessage authenticateAs(String username, String password) {
    if (username != null) {
      variableHeader.connectFlags.usernameFlag = username.isNotEmpty;
      payload.username = username;
    }
    if (password != null) {
      variableHeader.connectFlags.passwordFlag = password.isNotEmpty;
      payload.password = password;
    }
    return this;
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header.writeTo(variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(super.toString());
    sb.writeln('Client Identifier = ${payload.clientIdentifier}');
    sb.write('${variableHeader.toString()}');
    sb.writeln('${payload.toString()}');
    return sb.toString();
  }
}
