/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The unsubscribe acknowledgement message is sent by the broker to the client to confirm receipt
/// of an unsubscribe message.
class MqttUnsubscribeAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttUnsubscribeAckMessage class.
  MqttUnsubscribeAckMessage() {
    header = MqttHeader().asType(MqttMessageType.unsubscribeAck);
    _variableHeader = MqttUnsubscribeAckVariableHeader();
  }

  /// Initializes a new instance of the MqttUnsubscribeAckMessage class.
  MqttUnsubscribeAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
    messageStream.shrink();
  }

  /// Variable Header
  MqttUnsubscribeAckVariableHeader? _variableHeader;
  MqttUnsubscribeAckVariableHeader? get variableHeader => _variableHeader;

  /// Payload
  MqttUnsubscribeAckPayload? _payload;
  MqttUnsubscribeAckPayload? get payload => _payload;

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
        'MqttUnsubscribeAckMessage::writeTo - not implemented, message is receive only');
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    _variableHeader =
        MqttUnsubscribeAckVariableHeader.fromByteBuffer(messageStream);
    _payload = MqttUnsubscribeAckPayload.fromByteBuffer(
        header, variableHeader, messageStream);
    messageStream.shrink();
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.write(payload.toString());
    return sb.toString();
  }
}
