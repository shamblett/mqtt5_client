/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of the variable header for an MQTT Connect message.
///
/// The Variable Header for the CONNECT Packet contains the following fields
/// in this order: Protocol Name, Protocol Level, Connect Flags,
/// Keep Alive, and Properties.
class MqttConnectVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectVariableHeader() {
    protocolName = MqttClientProtocol.name;
    protocolVersion = MqttClientProtocol.version;
    connectFlags = MqttConnectFlags();
  }

  /// Initializes a new instance of the MqttVariableHeader class,
  /// populating it with data from a stream.
  MqttConnectVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  // The property set
  final _propertySet = MqttPropertyContainer();

  @override
  int length;

  /// Protocol name
  String protocolName = MqttClientProtocol.name;

  /// Protocol version
  int protocolVersion = MqttClientProtocol.version;

  /// Connect flags
  ///
  /// The Connect Flags byte contains several parameters specifying the
  /// behavior of the MQTT connection. It also indicates the
  /// presence or absence of fields in the payload.
  MqttConnectFlags connectFlags;

  /// Keep alive
  ///
  /// The Keep Alive is a time interval measured in seconds. It is the maximum
  /// time interval that is permitted to elapse between the point at which
  /// the Client finishes transmitting one MQTT Control Packet and the
  /// point it starts sending the next. It is the responsibility of the Client
  /// to ensure that the interval between MQTT Control Packets being sent does
  /// not exceed the Keep Alive value. If Keep Alive is non-zero and in the
  /// absence of sending any other MQTT Control Packets,
  /// the Client MUST send a ping request.
  ///
  /// If the Keep Alive value is non-zero and the Server does not receive an MQTT
  /// Control Packet from the Client within one and a half times the Keep Alive
  /// time period, it MUST close the Network Connection to the Client
  /// as if the network had failed.
  ///
  /// A Keep Alive value of 0 has the effect of turning off the Keep Alive mechanism.
  /// If Keep Alive is 0 the Client is not obliged to send MQTT Control Packets
  /// on any particular schedule.
  ///
  /// The broker may have other reasons to disconnect the Client, for instance because
  /// it is shutting down. Setting Keep Alive does not guarantee that the
  /// Client will remain connected.
  ///
  /// The actual value of the Keep Alive is application specific; typically, this is
  /// a few minutes. The maximum value of 65,535 is 18 hours 12 minutes and 15 seconds.
  int keepAlive = 0;

  static const sessionDoesNotExpire = 4294967295;

  /// Session expiry interval property
  ///
  /// If the Session Expiry Interval is absent the value 0 is used.
  /// If it is set to 0, or is absent, the Session ends when the
  /// Network Connection is closed.
  ///
  /// If the Session Expiry Interval is set to [sessionDoesNotExpire],
  /// the Session does not expire.
  ///
  /// Setting Clean Start true and a Session Expiry Interval of 0, is equivalent
  /// to setting Clean Session true in the MQTT Specification Version 3.1.1.
  /// Setting Clean Start false and no Session Expiry Interval, is equivalent to
  /// setting CleanSession to 0 in the MQTT Specification Version 3.1.1.
  ///
  /// A Client that only wants to process messages while connected will set Clean Start
  /// true and set the Session Expiry Interval to 0. It will not receive Application
  /// Messages published before it connected and has to subscribe afresh to any
  /// topics that it is interested in each time it connects.
  ///
  /// A Client might be connecting to a Server using a network that provides
  /// intermittent connectivity. This Client can use a short Session Expiry
  /// Interval so that it can reconnect when the network is available
  /// again and continue reliable message delivery. If the Client does not
  /// reconnect, allowing the Session to expire, then Application Messages
  /// will be lost.
  ///
  /// When a Client connects with a long Session Expiry Interval, it is
  /// requesting that the Server maintain its MQTT session state after it
  /// disconnects for an extended period. Clients should only connect with a
  /// long Session Expiry Interval if they intend to reconnect to the broker at some
  /// later point in time. When a Client has determined that it has no further
  /// use for the Session it should disconnect with a Session Expiry Interval set to 0.
  final _sessionExpiryInterval = 0;
  int get sessionExpiryInterval => _sessionExpiryInterval;
  set sessionExpiryInterval(int interval) {
    var property = MqttFourByteIntegerProperty(
        MqttPropertyIdentifier.sessionExpiryInterval);
    property.value = interval;
    _propertySet.add(property);
  }

  /// Receive maximum property
  ///
  /// The Client uses this value to limit the number of QoS 1 and QoS 2 publications that it
  /// is willing to process concurrently. There is no mechanism to limit the QoS 0
  /// publications that the Server might try to send hence a value of 0 is an error.
  ///
  /// The value of Receive Maximum applies only to the current Network Connection.
  /// If the Receive Maximum value is absent then its value defaults to its
  /// maximum value of 65,535.
  final _receiveMaximum = 0;
  int get receiveMaximum => _receiveMaximum;
  set receiveMaximum(int maximum) {
    if (maximum <= 0 || maximum > 65535) {
      throw ArgumentError.value(maximum, 'value must be between 1 and 65535');
    }
    var property =
        MqttTwoByteIntegerProperty(MqttPropertyIdentifier.receiveMaximum);
    property.value = maximum;
    _propertySet.add(property);
  }

  /// Maximum packet size property
  ///
  ///  The Maximum Packet Size the Client is willing to accept. If the
  ///  Maximum Packet Size is not present, no limit on the packet size is
  ///  imposed beyond the limitations in the protocol as a result of the
  ///  remaining length encoding and the protocol header sizes.
  ///
  /// The Client uses the Maximum Packet Size to inform the broker that it
  /// will not process packets exceeding this limit.
  ///
  ///  A value of 0 is an error.
  final _maximumPacketSize = 0;
  int get maximumPacketSize => _maximumPacketSize;
  set maximumPacketSize(int size) {
    if (size == 0) {
      throw ArgumentError.value(size, 'value must not be 0');
    }
    var property =
        MqttFourByteIntegerProperty(MqttPropertyIdentifier.maximumPacketSize);
    property.value = size;
    _propertySet.add(property);
  }

  /// Topic alias maximum property
  ///
  /// This value indicates the highest value that the Client will accept as a
  /// Topic Alias sent by the broker. The Client uses this value to limit the
  /// number of Topic Aliases that it is willing to hold on this Connection.
  ///
  /// A value of 0 indicates that the Client does not accept any Topic
  /// Aliases on this connection.
  final _topicAliasMaximum = 0;
  int get topicAliasMaximum => _topicAliasMaximum;
  set topicAliasMaximum(int maximum) {
    var property =
        MqttTwoByteIntegerProperty(MqttPropertyIdentifier.topicAliasMaximum);
    property.value = maximum;
    _propertySet.add(property);
  }

  /// Request response information property
  ///
  /// The Client uses this value to request the broker to return Response Information in
  /// the connection acknowledgement message. False indicates that the Server MUST NOT return
  /// Response Information. If true the broker MAY return Response Information
  /// in the connection acknowledgement message.
  final _requestResponseInformation = false;
  bool get requestResponseInformation => _requestResponseInformation;
  set requestResponseInformation(bool request) {
    var property =
        MqttByteProperty(MqttPropertyIdentifier.requestResponseInformation);
    property.value = request ? 1 : 0;
    _propertySet.add(property);
  }

  /// Request problem information property
  ///
  /// The Client uses this value to indicate whether the Reason String or
  /// User Properties are sent in the case of failures.
  ///
  /// If this value is true, the broker MAY return a Reason String or
  /// User Properties on any message where it is allowed.
  final _requestProblemInformation = true;
  bool get requestProblemInformation => _requestProblemInformation;
  set requestProblemInformation(bool request) {
    var property =
        MqttByteProperty(MqttPropertyIdentifier.requestProblemInformation);
    property.value = request ? 1 : 0;
    _propertySet.add(property);
  }

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  final _userProperties = <MqttStringPairProperty>[];
  List<MqttStringPairProperty> get userProperties => _userProperties;
  set userProperties(List<MqttStringPairProperty> properties) {
    for (var userProperty in properties) {
      userProperty.identifier = MqttPropertyIdentifier.userProperty;
      _propertySet.add(userProperty);
    }
  }

  /// Authentication method property
  ///
  /// A string containing the name of the authentication method
  /// used for extended authentication.
  ///
  /// If Authentication Method is absent, extended authentication is
  /// not performed.
  final _authenticationMethod = '';
  String get authenticationMethod => _authenticationMethod;
  set authenticationMethod(String method) {
    var property =
        MqttUtf8StringProperty(MqttPropertyIdentifier.authenticationMethod);
    property.value = method;
    _propertySet.add(property);
  }

  /// Authentication Data property
  ///
  /// Binary Data containing authentication data. It is a
  /// Protocol Error to include Authentication Data if there is no
  /// Authentication Method.
  final _authenticationData = typed.Uint8Buffer();
  typed.Uint8Buffer get authenticationData => _authenticationData;
  set authenticationData(typed.Uint8Buffer data) {
    var property =
        MqttBinaryDataProperty(MqttPropertyIdentifier.authenticationData);
    property.addBytes(data);
    _propertySet.add(property);
  }

  /// Encoder
  final MqttUtf8Encoding _enc = MqttUtf8Encoding();

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readProtocolName(variableHeaderStream);
    readProtocolVersion(variableHeaderStream);
    readConnectFlags(variableHeaderStream);
    readKeepAlive(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeProtocolName(variableHeaderStream);
    writeProtocolVersion(variableHeaderStream);
    writeConnectFlags(variableHeaderStream);
    writeKeepAlive(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    final enc = MqttUtf8Encoding();
    headerLength += enc.byteCount(protocolName);
    headerLength += 1; // protocolVersion
    headerLength += MqttConnectFlags.getWriteLength();
    headerLength += 2; // keepAlive
    return headerLength;
  }

  /// Protocol name
  void writeProtocolName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, protocolName);
  }

  /// Protocol version
  void writeProtocolVersion(MqttByteBuffer stream) {
    stream.writeByte(protocolVersion);
  }

  /// Keep alive
  void writeKeepAlive(MqttByteBuffer stream) {
    stream.writeShort(keepAlive);
  }

  /// Connect flags
  void writeConnectFlags(MqttByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  /// Protocol name
  void readProtocolName(MqttByteBuffer stream) {
    protocolName = MqttByteBuffer.readMqttString(stream);
    length += _enc.byteCount(protocolName);
  }

  /// Protocol version
  void readProtocolVersion(MqttByteBuffer stream) {
    protocolVersion = stream.readByte();
    length++;
  }

  /// Keep alive
  void readKeepAlive(MqttByteBuffer stream) {
    keepAlive = stream.readShort();
    length += 2;
  }

  /// Connect flags
  void readConnectFlags(MqttByteBuffer stream) {
    connectFlags = MqttConnectFlags.fromByteBuffer(stream);
    length += 1;
  }

  @override
  String toString() => 'Connect Variable Header: ProtocolName=$protocolName, '
      'ProtocolVersion=$protocolVersion, '
      'ConnectFlags=${connectFlags.toString()}, '
      'KeepAlive=$keepAlive';
}
