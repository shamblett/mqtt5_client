/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Message that indicates a connection acknowledgement.
///
/// The connection acknowledgement message is the message sent by the broker in response
/// to a connect message received from the client.
class MqttConnectAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttConnectAckMessage class.
  /// Only called via the MqttMessage.Create operation during processing
  /// of an Mqtt message stream.
  MqttConnectAckMessage() {
    header = MqttHeader().asType(MqttMessageType.connectAck);
    _variableHeader = MqttConnectAckVariableHeader();
  }

  /// Initializes a new instance of the MqttConnectAckMessage from a byte buffer
  MqttConnectAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  MqttConnectAckVariableHeader? _variableHeader;

  /// The variable header contents.
  MqttConnectAckVariableHeader? get variableHeader => _variableHeader;

  /// Session Expiry Interval.
  int? get sessionExpiryInterval => _variableHeader!.sessionExpiryInterval;

  /// Receive Maximum.
  int? get receiveMaximum => _variableHeader!.receiveMaximum;

  /// Maximum QoS.
  int? get maximumQos => _variableHeader!.maximumQos;

  /// Retain Available.
  bool get retainAvailable => _variableHeader!.retainAvailable;

  /// Maximum Packet Size
  int? get maximumPacketSize => _variableHeader!.maximumPacketSize;

  /// Assigned client Identifier.
  String? get assignedClientIdentifier =>
      _variableHeader!.assignedClientIdentifier;

  /// Topic Alias Maximum.
  int? get topicAliasMaximum => _variableHeader!.topicAliasMaximum;

  /// Reason String.
  String? get reasonString => _variableHeader!.reasonString;

  /// User Property
  List<MqttUserProperty>? get userProperty => _variableHeader!.userProperty;

  /// Wildcard Subscription Available.
  bool get wildcardSubscriptionsAvailable =>
      _variableHeader!.wildcardSubscriptionsAvailable;

  /// Subscription Identifiers Available.
  bool get subscriptionIdentifiersAvailable =>
      _variableHeader!.subscriptionIdentifiersAvailable;

  /// Shared Subscription Available.
  bool get sharedSubscriptionAvailable =>
      _variableHeader!.sharedSubscriptionAvailable;

  /// Server Keep Alive.
  int? get serverKeepAlive => _variableHeader!.serverKeepAlive;

  /// Response Information
  String? get responseInformation => _variableHeader!.responseInformation;

  /// Server Reference.
  String? get serverReference => _variableHeader!.serverReference;

  /// Authentication Method.
  String? get authenticationMethod => _variableHeader!.authenticationMethod;

  /// Authentication Data.
  typed.Uint8Buffer? get authenticationData =>
      _variableHeader!.authenticationData;

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    _variableHeader =
        MqttConnectAckVariableHeader.fromByteBuffer(messageStream);
    messageStream.shrink();
  }

  /// Writes a message to the supplied stream. Not implemented for this message.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    throw UnimplementedError(
        'MqttConnectAckMessage::writeTo - message is receive only');
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.write(_variableHeader.toString());
    return sb.toString();
  }
}
