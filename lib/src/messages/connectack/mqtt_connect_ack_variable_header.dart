// ignore_for_file: no-magic-number

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The Variable Header of the Connect Acknowledgement message contains the following fields
/// in the order: Connect Acknowledge Flags, Connect Reason Code, and Properties.
class MqttConnectAckVariableHeader implements MqttIVariableHeader {
  /// Connect acknowledge message flags
  MqttConnectAckFlags connectAckFlags = MqttConnectAckFlags();

  /// Session present
  bool sessionPresent = false;

  /// Reason Code
  MqttConnectReasonCode? reasonCode = MqttConnectReasonCode.notSet;

  /// Length of the recieved message.
  @override
  int length = 0;

  /// The property set
  final _propertySet = MqttPropertyContainer();

  int? _sessionExpiryInterval = 0;

  int? _receiveMaximum = 65535;

  int? _maximumQos = 2;

  bool _retainAvailable = false;

  int? _maximumPacketSize = 0;

  String? _assignedClientIdentifier;

  int? _topicAliasMaximum = 0;

  String? _reasonString;

  List<MqttUserProperty>? _userProperty;

  bool _wildcardSubscriptionsAvailable = true;

  bool _subscriptionIdentifiersAvailable = true;

  bool _sharedSubscriptionAvailable = true;

  int? _serverKeepAlive = 0;

  String? _responseInformation;

  String? _serverReference;

  String? _authenticationMethod;

  typed.Uint8Buffer? _authenticationData;

  /// Session Expiry Interval.
  ///
  /// The broker uses this property to inform the client that it is using a value
  /// other than that sent by the client in the Connect Message.
  int? get sessionExpiryInterval => _sessionExpiryInterval;

  /// Receive Maximum.
  ///
  /// The broker uses this value to limit the number of QoS 1 and QoS 2 publications
  /// that it is willing to process concurrently for the client. It does not provide a
  /// mechanism to limit the QoS 0 publications that the client might try to send.
  ///
  /// A value of 65535 indicates not set.
  int? get receiveMaximum => _receiveMaximum;

  /// Maximum QoS.
  ///
  /// A client does not need to support QoS 1 or QoS 2 publish messages.
  /// If this is the case, the client simply restricts the maximum QoS field in
  /// any Subscribe messages it sends to a value it can support.
  ///
  /// If a client receives a Maximum QoS from a broker, it must not send Publish messages at
  /// a QoS level exceeding the Maximum QoS level specified.
  ///
  /// A value of 2 is the default.
  int? get maximumQos => _maximumQos;

  /// Retain Available.
  ///
  /// A client receiving Retain Available set to false from the broker
  /// must not send a Publish message with retain available set true.
  bool get retainAvailable => _retainAvailable;

  /// Maximum Packet Size.
  ///
  /// A value of zero indicates this property is not set.
  int? get maximumPacketSize => _maximumPacketSize;

  /// Assigned Client Identifier.
  ///
  /// The client Identifier which was assigned by the broker because a zero length client Identifier
  /// was found in the Connect message.
  String? get assignedClientIdentifier => _assignedClientIdentifier;

  /// Topic Alias Maximum.
  ///
  /// This value indicates the highest value that the broker will accept as a
  /// Topic Alias sent by the client.
  /// The client MUST NOT send a Topic Alias in a publish message to the broker
  /// greater than this value.
  /// If Topic Alias Maximum is 0, the client must not send any Topic
  /// Aliases on to the broker.
  int? get topicAliasMaximum => _topicAliasMaximum;

  /// Reason String.
  ///
  /// The Reason String is a human readable string designed for diagnostics only.
  String? get reasonString => _reasonString;

  /// User Property.
  ///
  /// This property can be used to provide additional information to the client including
  /// diagnostic information.
  /// The User Property is allowed to appear multiple times to represent multiple name, value pairs.
  /// The same name is allowed to appear more than once.
  List<MqttUserProperty>? get userProperty => _userProperty;

  /// Wildcard Subscription Available.
  ///
  /// False means that Wildcard Subscriptions are not supported.
  /// True means Wildcard Subscriptions are supported. The default is that Wildcard
  /// Subscriptions are supported.
  bool get wildcardSubscriptionsAvailable => _wildcardSubscriptionsAvailable;

  /// Subscription Identifiers Available.
  ///
  /// False means that Subscription Identifiers are not supported.
  /// True means Subscription Identifiers are supported. The default is that
  /// Subscription Identifiers are supported.
  bool get subscriptionIdentifiersAvailable =>
      _subscriptionIdentifiersAvailable;

  /// Shared Subscription Available.
  ///
  /// False means that Shared Subscriptions are not supported.
  /// True means Shared Subscriptions are supported. The default is that
  /// Shared Subscriptions are supported.
  bool get sharedSubscriptionAvailable => _sharedSubscriptionAvailable;

  /// Server Keep Alive.
  ///
  ///  If the broker sends a Server Keep Alive the client must use this value
  ///  instead of the keep alive value the client may have sent in the Connect message.
  ///
  ///  The primary use of the Server Keep Alive is for the broker to inform the client
  ///  that it will disconnect the client for inactivity sooner than the keep alive
  ///  specified by the client.
  ///
  /// A value of 0 indicates not set by the broker.
  int? get serverKeepAlive => _serverKeepAlive;

  /// Response Information.
  ///
  /// This string is used as the basis for creating a Response Topic.
  ///
  /// A common use of this is to pass a globally unique portion of the topic tree
  /// which is reserved for this client for at least the lifetime of its Session.
  String? get responseInformation => _responseInformation;

  /// Server Reference.
  ///
  /// A string to indicate another broker to use.
  String? get serverReference => _serverReference;

  /// Authentication Method.
  ///
  /// A string containing the name of the authentication method.
  String? get authenticationMethod => _authenticationMethod;

  /// Authentication Data.
  ///
  /// The contents of this data are defined by the authentication method and the state
  /// of already exchanged authentication data.
  typed.Uint8Buffer? get authenticationData => _authenticationData;

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader from a byte buffer.
  MqttConnectAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// Writes the variable header to the supplied stream.
  /// Not implemented for this message
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    sessionPresent
        ? variableHeaderStream.writeByte(1)
        : variableHeaderStream.writeByte(0);
    variableHeaderStream.writeByte(mqttConnectReasonCode.asInt(reasonCode));
    _propertySet.writeTo(variableHeaderStream);
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    // Connect ack flags
    connectAckFlags.readFrom(variableHeaderStream);
    sessionPresent = connectAckFlags.sessionPresent;
    length += 1;
    // Reason code
    var byte = variableHeaderStream.readByte();
    reasonCode = mqttConnectReasonCode.fromInt(byte);
    length += 1;
    // Properties
    variableHeaderStream.shrink();
    _propertySet.readFrom(variableHeaderStream);
    _processProperties();
    variableHeaderStream.shrink();
    length += _propertySet.getWriteLength();
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => _propertySet.length() + 2;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Session Present = ${connectAckFlags.sessionPresent}');
    sb.writeln(
      'Connect Reason Code = ${mqttConnectReasonCode.asString(reasonCode)}',
    );
    sb.writeln('Session Expiry Interval = $sessionExpiryInterval');
    sb.writeln('Receive Maximum = $receiveMaximum');
    sb.writeln('Maximum QoS = $maximumQos');
    sb.writeln('Retain Available = $retainAvailable');
    sb.writeln('Maximum Packet Size = $maximumPacketSize');
    sb.writeln('Assigned client Identifier = $assignedClientIdentifier');
    sb.writeln('Topic Alias Maximum = $topicAliasMaximum');
    sb.writeln('Reason String = $reasonString');
    sb.writeln(
      'Wildcard Subscription Available = $wildcardSubscriptionsAvailable',
    );
    sb.writeln(
      'Subscription Identifiers Available = $subscriptionIdentifiersAvailable',
    );
    sb.writeln('Shared Subscription Available = $sharedSubscriptionAvailable');
    sb.writeln('broker Keep Alive = $serverKeepAlive');
    sb.writeln('Response Information = $responseInformation');
    sb.writeln('broker Reference = $serverReference');
    sb.writeln('Authentication Method = $authenticationMethod');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }

  // Process the properties read from the byte stream
  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
        'MqttConnectAckVariableHeader::_processProperties, message properties received are invalid',
      );
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        case MqttPropertyIdentifier.sessionExpiryInterval:
          _sessionExpiryInterval = property.value;
          break;
        case MqttPropertyIdentifier.receiveMaximum:
          _receiveMaximum = property.value;
          break;
        case MqttPropertyIdentifier.maximumQos:
          _maximumQos = property.value;
          break;
        case MqttPropertyIdentifier.retainAvailable:
          _retainAvailable = property.value == 1;
          break;
        case MqttPropertyIdentifier.maximumPacketSize:
          _maximumPacketSize = property.value;
          break;
        case MqttPropertyIdentifier.assignedClientIdentifier:
          _assignedClientIdentifier = property.value;
          break;
        case MqttPropertyIdentifier.topicAliasMaximum:
          _topicAliasMaximum = property.value;
          break;
        case MqttPropertyIdentifier.reasonString:
          _reasonString = property.value;
          break;
        case MqttPropertyIdentifier.wildcardSubscriptionAvailable:
          _wildcardSubscriptionsAvailable = property.value == 1;
          break;
        case MqttPropertyIdentifier.subscriptionIdentifierAvailable:
          _subscriptionIdentifiersAvailable = property.value == 1;
          break;
        case MqttPropertyIdentifier.sharedSubscriptionAvailable:
          _sharedSubscriptionAvailable = property.value == 1;
          break;
        case MqttPropertyIdentifier.serverKeepAlive:
          _serverKeepAlive = property.value;
          break;
        case MqttPropertyIdentifier.responseInformation:
          _responseInformation = property.value;
          break;
        case MqttPropertyIdentifier.serverReference:
          _serverReference = property.value;
          break;
        case MqttPropertyIdentifier.authenticationMethod:
          _authenticationMethod = property.value;
          break;
        case MqttPropertyIdentifier.authenticationData:
          _authenticationData = typed.Uint8Buffer()..addAll(property.value);
          break;
        default:
          if (property.identifier != MqttPropertyIdentifier.userProperty) {
            MqttLogger.log(
              'MqttConnectAckVariableHeader::_processProperties, unexpected property type'
              'received, identifier is ${property.identifier}, ignoring',
            );
          }
      }
      _userProperty = _propertySet.userProperties;
    }
  }
}
