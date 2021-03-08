/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A subscribe acknowledgement message is sent by the broker to the client
/// to confirm receipt and processing of a subscribe message.
///
/// A subscribe acknowledgement message contains a list of reason codes, that specify
/// the maximum QoS level that was granted or the error which was found for
/// each Subscription that was requested by the subscribe message.
class MqttSubscribeAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage() {
    header = MqttHeader().asType(MqttMessageType.subscribeAck);
    _variableHeader = MqttSubscribeAckVariableHeader();
    _payload = MqttSubscribeAckPayload();
  }

  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Variable Header
  MqttSubscribeAckVariableHeader? _variableHeader;
  MqttSubscribeAckVariableHeader? get variableHeader => _variableHeader;

  /// Payload
  MqttSubscribeAckPayload? _payload;
  MqttSubscribeAckPayload? get payload => _payload;

  /// The message identifier
  int get messageIdentifier => _variableHeader!.messageIdentifier;

  /// Reason codes, one for each topic subscribed
  List<MqttSubscribeReasonCode?> get reasonCodes => _payload!.reasonCodes;

  /// Reason String.
  String? get reasonString => _variableHeader!.reasonString;

  /// User Property.
  List<MqttUserProperty> get userProperty => _variableHeader!.userProperty;

  /// Writes the message to the supplied stream.
  /// Not implemented, message is receive only.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    throw UnimplementedError(
        'MqttSubscribeAckMessage::writeTo - not implemented, message is receive only');
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    _variableHeader =
        MqttSubscribeAckVariableHeader.fromByteBuffer(messageStream);
    _payload = MqttSubscribeAckPayload.fromByteBuffer(
        header, variableHeader, messageStream);
    messageStream.shrink();
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.write(variableHeader);
    sb.write(payload);
    return sb.toString();
  }
}
