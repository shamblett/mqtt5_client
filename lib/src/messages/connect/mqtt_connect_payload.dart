/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Class that contains details related to an MQTT Connect messages payload.
///
/// The Payload of the Connect message [MqttConnectMessage] contains one or
/// more length-prefixed fields, whose presence is determined by the
/// flags in the Variable Header.
///
/// These fields, if present, MUST appear in the order client Identifier,
/// Will Properties, Will Topic, Will Payload, User Name, Password.
class MqttConnectPayload implements MqttIPayload {
  /// Initializes a new instance of the MqttConnectPayload class.
  MqttConnectPayload(this.variableHeader);

  /// Variable header, needed for payload encoding
  MqttConnectVariableHeader? variableHeader = MqttConnectVariableHeader();

  /// Will Properties.
  ///
  /// Note that unless the will flag,
  /// [MqttConnectFlags.willFlag], in the variable header is
  /// set these properties will not be encoded in the payload even if
  /// they are set.
  MqttWillProperties willProperties = MqttWillProperties();

  /// client identifier.
  ///
  /// The client Identifier (ClientID) identifies the client to the broker.
  /// Each client connecting to the broker has a unique ClientID.
  /// The ClientID MUST be used by Clients and by brokers to identify state
  /// that they hold relating to this MQTT Session between the client and the broker.
  ///
  /// The ClientID MUST be present and is the first field
  /// in the Connect message Payload and must be a
  /// UTF-8 Encoded String.
  ///
  /// The broker MUST allow ClientID’s which are between 1 and 23 UTF-8
  /// encoded bytes in length, and that contain only the characters
  /// "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".
  /// The broker MAY allow ClientID’s that contain more than 23 encoded bytes.
  /// The broker MAY allow ClientID’s that contain characters not
  /// included in the list given above.
  ///
  /// If the broker rejects the ClientID it MAY respond to the Connect message
  /// with a Connect Acknowledgement message [MqttConnectAckMessage] using
  /// Reason Code client Identifier not valid [MqttConnectReasonCode.clientIdentifierNotValid].
  String clientIdentifier = '';

  /// Will topic.
  ///
  /// If the Will Flag is set [MqttConnectFlags.willFlag], the Will Topic is the
  /// encoded in the Payload.
  String? willTopic;

  /// Will payload.
  ///
  /// Note that unless the will flag,
  /// [MqttConnectFlags.willFlag], in the variable header is
  /// set this payload will not be encoded in the payload even if
  /// it is set.
  typed.Uint8Buffer willPayload = typed.Uint8Buffer();

  String? _username;

  /// User name
  String? get username => _username;

  set username(String? name) => _username = name != null ? name.trim() : name;
  String? _password;

  /// Password
  String? get password => _password;

  set password(String? pwd) => _password = pwd != null ? pwd.trim() : pwd;

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    throw UnimplementedError(
        'MqttConnectPayload::readFrom - message is transmit only');
  }

  void _serialize(MqttByteBuffer payloadStream) {
    payloadStream.writeMqttStringM(clientIdentifier);
    if (variableHeader!.connectFlags.willFlag) {
      willProperties.writeTo(payloadStream);
      payloadStream.writeMqttStringM(willTopic);
      payloadStream.write(willPayload);
    }
    if (variableHeader!.connectFlags.usernameFlag) {
      payloadStream.writeMqttStringM(username);
    }
    if (variableHeader!.connectFlags.passwordFlag) {
      payloadStream.writeMqttStringM(password);
    }
  }

  /// Writes the connect message payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) => _serialize(payloadStream);

  @override
  int getWriteLength() {
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    _serialize(stream);
    return stream.length;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Will topic = $willTopic');
    sb.write('User name = ');
    username != null ? sb.writeln('$username') : sb.writeln('not set');
    sb.write('Password = ');
    password != null ? sb.writeln('$password') : sb.writeln('not set');
    return sb.toString();
  }
}
