/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Factory for generating instances of MQTT Messages
class MqttMessageFactory {
  /// Gets an instance of an MqttMessage based on the message type requested
  /// from a byte stream.
  static MqttMessage? getMessage(
      MqttHeader header, MqttByteBuffer messageStream) {
    MqttMessage? message;
    switch (header.messageType) {
      case MqttMessageType.connect:
      case MqttMessageType.pingRequest:
      case MqttMessageType.subscribe:
      case MqttMessageType.unsubscribe:
        // Send only messages should not be decoded from a byte stream, i.e. received.
        MqttLogger.log(
            'MqttMessage::getMessage - ERROR send only message received, returning null');
        break;
      case MqttMessageType.connectAck:
        message = MqttConnectAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publish:
        message = MqttPublishMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishAck:
        message = MqttPublishAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishComplete:
        message =
            MqttPublishCompleteMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishReceived:
        message =
            MqttPublishReceivedMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishRelease:
        message =
            MqttPublishReleaseMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.subscribeAck:
        message = MqttSubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.unsubscribeAck:
        message =
            MqttUnsubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.pingResponse:
        message = MqttPingResponseMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.disconnect:
        message = MqttDisconnectMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.auth:
        message = MqttAuthenticateMessage.fromByteBuffer(header, messageStream);
        break;
      default:
        throw MqttInvalidHeaderException(
            'The Message Type specified ($header.messageType) is not a valid '
            'MQTT Message type or currently not supported.');
    }
    return message;
  }
}
