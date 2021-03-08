/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Factory for generating instances of MQTT message properties
class MqttPropertyFactory {
  /// Gets an instance of an MqttIProperty.
  /// The stream must be positioned on a property identifier, i.e.
  /// after the property length field in a message.
  static MqttIProperty get(MqttByteBuffer stream) {
    /// Get the identifier then the property value.
    /// If a valid property cannot be constructed a byte property with
    /// an identifier of not set is returned.
    final identifier = mqttPropertyIdentifier.fromInt(stream.peekByte());
    switch (identifier) {
      case MqttPropertyIdentifier.payloadFormatIndicator:
      case MqttPropertyIdentifier.requestProblemInformation:
      case MqttPropertyIdentifier.requestResponseInformation:
      case MqttPropertyIdentifier.maximumQos:
      case MqttPropertyIdentifier.retainAvailable:
      case MqttPropertyIdentifier.wildcardSubscriptionAvailable:
      case MqttPropertyIdentifier.subscriptionIdentifierAvailable:
      case MqttPropertyIdentifier.sharedSubscriptionAvailable:
      case MqttPropertyIdentifier.notSet:
        final property = MqttByteProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.messageExpiryInterval:
      case MqttPropertyIdentifier.sessionExpiryInterval:
      case MqttPropertyIdentifier.willDelayInterval:
      case MqttPropertyIdentifier.maximumPacketSize:
        final property = MqttFourByteIntegerProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.contentType:
      case MqttPropertyIdentifier.responseTopic:
      case MqttPropertyIdentifier.assignedClientIdentifier:
      case MqttPropertyIdentifier.authenticationMethod:
      case MqttPropertyIdentifier.responseInformation:
      case MqttPropertyIdentifier.serverReference:
      case MqttPropertyIdentifier.reasonString:
        final property = MqttUtf8StringProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.correlationdata:
      case MqttPropertyIdentifier.authenticationData:
        final property = MqttBinaryDataProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.subscriptionIdentifier:
        final property = MqttVariableByteIntegerProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.serverKeepAlive:
      case MqttPropertyIdentifier.receiveMaximum:
      case MqttPropertyIdentifier.topicAliasMaximum:
      case MqttPropertyIdentifier.topicAlias:
        final property = MqttTwoByteIntegerProperty();
        return property..readFrom(stream);
      case MqttPropertyIdentifier.userProperty:
        final property = MqttUserProperty();
        return property..readFrom(stream);
      default:
        return MqttByteProperty(MqttPropertyIdentifier.notSet);
    }
  }
}
