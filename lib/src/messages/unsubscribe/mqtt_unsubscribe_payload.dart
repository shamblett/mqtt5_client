/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// The payload for the unsubscribe message contains the list of
/// topic filters that the client wishes to unsubscribe from
class MqttUnsubscribePayload extends MqttIPayload {
  /// Initializes a new instance of the MqttUnsubscribePayload class.
  MqttUnsubscribePayload();

  final _subscriptions = <MqttSubscriptionTopic>[];

  /// The subscribe topics to unsubscribe.
  List<MqttSubscriptionTopic> get subscriptions => _subscriptions;

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.write(_serialize());
  }

  /// Creates a payload from the specified header stream.
  /// Not implemented, message is send only
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    throw UnimplementedError(
        'MqttUnsubscribePayload::readFrom - unimplemented, message is send only');
  }

  // Serialize
  typed.Uint8Buffer _serialize() {
    final buffer = typed.Uint8Buffer();
    if (_subscriptions.isEmpty) {
      return buffer;
    }
    final stream = MqttByteBuffer(buffer);
    for (final topic in _subscriptions) {
      stream.writeMqttStringM(topic.rawTopic);
    }
    return buffer;
  }

  /// Gets the length of the payload in bytes when written to a stream.
  @override
  int getWriteLength() => _serialize().length;

  /// Adds a new subscription string to the collection of subscriptions.
  void addStringSubscription(String topic) {
    _subscriptions.add(MqttSubscriptionTopic(topic));
  }

  /// Adds a new subscription topic to the collection of subscriptions.
  void addTopicSubscription(MqttSubscriptionTopic topic) {
    _subscriptions.add((topic));
  }

  /// Clears the subscriptions.
  void clear() {
    _subscriptions.clear();
  }

  /// Is valid, there must be at least one topic
  bool get isValid => _subscriptions.isNotEmpty;

  @override
  String toString() {
    final sb = StringBuffer();
    for (final subscription in _subscriptions) {
      sb.writeln('Subscription = $subscription');
    }
    return sb.toString();
  }
}
