/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The payload contains a list of reason codes. Each reason code corresponds to a
/// topic filter in the subscribe message being acknowledged.
class MqttSubscribeAckPayload extends MqttIPayload {
  /// Initializes a new instance of the MqttSubscribeAckPayload class.
  MqttSubscribeAckPayload();

  /// Initializes a new instance of the MqttSubscribeAckPayload class.
  MqttSubscribeAckPayload.fromByteBuffer(
      this.header, this.variableHeader, MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  int _length = 0;

  /// Receive length
  int get length => _length;

  /// Message header
  MqttHeader? header;

  /// Variable header
  MqttSubscribeAckVariableHeader? variableHeader;

  /// Reason codes, one for each topic subscribed
  final _reasonCodes = <MqttSubscribeReasonCode?>[];
  List<MqttSubscribeReasonCode?> get reasonCodes => _reasonCodes;

  /// Writes the payload to the supplied stream.
  /// Not impemented, message is receive only.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    throw UnimplementedError(
        'MqttSubscribeAckPayload::writeTo - not implemented, message is receive only');
  }

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    final payloadLength = header!.messageSize - variableHeader!.length;
    for (var i = 0; i < payloadLength; i++) {
      _reasonCodes
          .add(mqttSubscribeReasonCode.fromInt(payloadStream.readByte()));
      _length += 1;
    }
  }

  /// Gets the length of the payload in bytes when written to a stream.
  /// Always 0, message is receive only
  @override
  int getWriteLength() => 0;

  @override
  String toString() {
    final sb = StringBuffer();
    for (final value in _reasonCodes) {
      if (value != null) {
        sb.writeln('Reason Code = ${mqttSubscribeReasonCode.asString(value)}');
      }
    }
    return sb.toString();
  }
}
