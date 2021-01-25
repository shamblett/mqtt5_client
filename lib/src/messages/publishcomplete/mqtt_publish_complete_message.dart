/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The publish complete message is the response to a publisg release message.
/// It is the fourth and final message of the QoS 2 protocol exchange.
class MqttPublishCompleteMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage() {
    header = MqttHeader().asType(MqttMessageType.publishComplete);
    variableHeader = MqttPublishCompleteVariableHeader(header);
  }

  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader =
        MqttPublishCompleteVariableHeader.fromByteBuffer(header, messageStream);
    messageStream.shrink();
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  late MqttPublishCompleteVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishCompleteMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the reason code of the MqttMessage.
  MqttPublishCompleteMessage withReasonCode(MqttPublishReasonCode reason) {
    variableHeader.reasonCode = reason;
    return this;
  }

  /// The message identifier
  int get messageIdentifier => variableHeader.messageIdentifier;

  /// Publish reason code
  MqttPublishReasonCode? get reasonCode => variableHeader.reasonCode;

  /// Reason String.
  String? get reasonString => variableHeader.reasonString;

  /// User Property.
  List<MqttUserProperty> get userProperty => variableHeader.userProperty;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
