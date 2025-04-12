/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The payload contains a list of reason codes. Each reason code corresponds to a
/// topic filter in the unsubscribe message being acknowledged.
class MqttUnsubscribeAckPayload extends MqttIPayload {
  /// Message header
  MqttHeader? header;

  /// Variable header
  MqttUnsubscribeAckVariableHeader? variableHeader;

  int _length = 0;

  final _reasonCodes = <MqttSubscribeReasonCode?>[];

  /// Receive length
  int get length => _length;

  /// Reason codes, one for each topic subscribed
  List<MqttSubscribeReasonCode?> get reasonCodes => _reasonCodes;

  /// Initializes a new instance of the MqttUnsubscribeAckPayload class.
  MqttUnsubscribeAckPayload();

  /// Initializes a new instance of the MqttUnsubscribeAckPayload class.
  MqttUnsubscribeAckPayload.fromByteBuffer(
    this.header,
    this.variableHeader,
    MqttByteBuffer payloadStream,
  ) {
    readFrom(payloadStream);
  }

  /// Writes the payload to the supplied stream.
  /// Not implemented, message is receive only.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    throw UnimplementedError(
      'MqttUnsubscribeAckPayload::writeTo - not implemented, message is receive only',
    );
  }

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    final payloadLength = header!.messageSize - variableHeader!.length;
    for (var i = 0; i < payloadLength; i++) {
      _reasonCodes.add(
        mqttSubscribeReasonCode.fromInt(payloadStream.readByte()),
      );
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
    if (_reasonCodes.isEmpty) {
      sb.writeln('No reason codes received');
    }
    for (final value in _reasonCodes) {
      sb.writeln(' Reason Code = ${mqttSubscribeReasonCode.asString(value)}');
    }
    return sb.toString();
  }
}
