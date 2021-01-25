/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A publish acknowledge messageis the response to a publish message with QoS 1.
class MqttPublishAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage() {
    header = MqttHeader().asType(MqttMessageType.publishAck);
    _variableHeader = MqttPublishAckVariableHeader(header);
  }

  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    _variableHeader =
        MqttPublishAckVariableHeader.fromByteBuffer(header, messageStream);
    messageStream.shrink();
  }

  MqttPublishAckVariableHeader? _variableHeader;

  /// Gets the variable header contents. Contains extended
  /// metadata about the message.
  MqttPublishAckVariableHeader? get variableHeader => _variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader!.getWriteLength(), messageStream);
    variableHeader!.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishAckMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader!.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the reason code of the MqttMessage.
  MqttPublishAckMessage withReasonCode(MqttPublishReasonCode reason) {
    variableHeader!.reasonCode = reason;
    return this;
  }

  /// The message identifier
  int get messageIdentifier => variableHeader!.messageIdentifier;

  /// Publish reason code
  MqttPublishReasonCode? get reasonCode => variableHeader!.reasonCode;

  /// Reason String.
  String? get reasonString => variableHeader!.reasonString;

  /// User Property.
  List<MqttUserProperty> get userProperty => variableHeader!.userProperty;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
