/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

///
/// The subscription payload topic class.
/// Comprises a topic and its associated topic option.
class MqttSubscribePayloadTopic {
  /// Construction
  MqttSubscribePayloadTopic(this.topic, [MqttSubscriptionOption? option]) {
    if (option != null) {
      this.option = option;
    }
  }

  /// The topic
  MqttSubscriptionTopic topic;

  /// The Subscription option
  MqttSubscriptionOption option = MqttSubscriptionOption();
}

/// The payload of a subscribe message  contains a list of topic filters indicating the
/// topics to which the client wants to subscribe. Each topic filter is followed by a
/// subscription options value.
///
/// The payload must contain at least one topic filter and subscription
/// options pair.
class MqttSubscribePayload implements MqttIPayload {
  /// Initializes a new instance of the MqttSubscribePayload class.
  MqttSubscribePayload();

  /// Variable header
  MqttIVariableHeader? variableHeader;

  /// Message header
  MqttHeader? header;

  // The list of subscriptions.
  final _subscriptions = <MqttSubscribePayloadTopic>[];
  List<MqttSubscribePayloadTopic> get subscriptions => _subscriptions;

  // UTF8 encoder
  final _enc = MqttUtf8Encoding();

  // Serialize the topics.
  typed.Uint8Buffer _serialize() {
    final buffer = typed.Uint8Buffer();
    if (!isValid) {
      return buffer;
    }
    for (final topic in _subscriptions) {
      buffer.addAll(_enc.toUtf8(topic.topic.rawTopic!));
      buffer.add(topic.option.serialize());
    }
    return buffer;
  }

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    if (!isValid) {
      return;
    }
    payloadStream.addAll(_serialize());
  }

  /// Creates a payload from the specified header stream.
  /// Not implemented, the subscribe message is send only.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    throw UnimplementedError(
        'MqttSubscribePayload::writeTo - not implemented, mesage is send only');
  }

  /// Gets the length of the payload in bytes when written to a stream.
  @override
  int getWriteLength() => _serialize().length;

  /// Adds a new subscription to the collection of subscriptions.
  void addSubscription(MqttSubscriptionTopic topic,
      [MqttSubscriptionOption? option]) {
    final subTopic = MqttSubscribePayloadTopic(topic, option);
    _subscriptions.add(subTopic);
  }

  /// Clears the subscriptions.
  void clearSubscriptions() {
    _subscriptions.clear();
  }

  /// Check validity, there must be at least one subscription topic before the
  /// subscription message can be sent.
  bool get isValid => _subscriptions.isNotEmpty;

  ///
  /// Number of topic subscriptions
  int get count => _subscriptions.length;

  @override
  String toString() {
    final sb = StringBuffer();
    for (var topic in _subscriptions) {
      sb.write('Topic = ${topic.topic}, Option = ${topic.option}');
    }
    return sb.toString();
  }
}
