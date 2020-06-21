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
  static MqttMessage getMessage(
      MqttHeader header, MqttByteBuffer messageStream) {
    MqttMessage message;
    switch (header.messageType) {
      case MqttMessageType.connect:
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
      case MqttMessageType.subscribe:
        break;
      case MqttMessageType.subscribeAck:
        message = MqttSubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.unsubscribe:
        break;
        break;
      case MqttMessageType.unsubscribeAck:
        message =
            MqttUnsubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.pingRequest:
        break;
      case MqttMessageType.pingResponse:
        message = MqttPingResponseMessage.fromHeader(header);
        break;
      case MqttMessageType.disconnect:
        message = MqttDisconnectMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.auth:
        message = MqttAuthenticateMessage.fromByteBuffer(header, messageStream);
        break;
      default:
        throw InvalidHeaderException(
            'The Message Type specified ($header.messageType) is not a valid '
            'MQTT Message type or currently not supported.');
    }
    return message;
  }
}
