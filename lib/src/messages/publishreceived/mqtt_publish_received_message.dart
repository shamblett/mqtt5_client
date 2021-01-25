/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A publish receive message is the response to a publish message with QoS 2.
/// It is the second packet of the QoS 2 protocol exchange.
class MqttPublishReceivedMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishReceivedMessage class.
  MqttPublishReceivedMessage() {
    header = MqttHeader().asType(MqttMessageType.publishReceived);
    variableHeader = MqttPublishReceivedVariableHeader(header);
  }

  /// Initializes a new instance of the MqttPublishReceivedMessage class.
  MqttPublishReceivedMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader =
        MqttPublishReceivedVariableHeader.fromByteBuffer(header, messageStream);
    messageStream.shrink();
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  late MqttPublishReceivedVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishReceivedMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the reason code of the MqttMessage.
  MqttPublishReceivedMessage withReasonCode(MqttPublishReasonCode reason) {
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

  /// Is valid
  @override
  bool get isValid => variableHeader.reasonCode != MqttPublishReasonCode.notSet;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
