/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of an MQTT Publish Acknowledgement Message, used to ACK a
/// publish message that has it's QOS set to AtLeast or Exactly Once.
class MqttPublishAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage() {
    header = MqttHeader().asType(MqttMessageType.publishAck);
    variableHeader = MqttPublishAckVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader = MqttPublishAckVariableHeader.fromByteBuffer(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message
  MqttPublishAckVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishAckMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
