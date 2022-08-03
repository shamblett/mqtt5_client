/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Will Properties
///
/// If the Will Flag is set , the Will Properties is the next field in the Payload.
/// The Will Properties field defines the Application Message properties to be
/// sent with the Will Message when it is published, and properties which define
/// when to publish the Will Message. The Will Properties consists of a
/// Property Length and the Properties.
class MqttWillProperties {
  final _propertySet = MqttPropertyContainer();

  /// Will Delay Interval
  ///
  /// The Will Delay Interval in seconds. If the Will Delay Interval is absent,
  /// the default value is 0 and there is no delay before the Will Message
  /// is published.
  int _willDelayInterval = 0;
  int get willDelayInterval => _willDelayInterval;
  set willDelayInterval(int delay) {
    if (delay != 0) {
      final property =
          MqttFourByteIntegerProperty(MqttPropertyIdentifier.willDelayInterval);
      property.value = delay;
      _propertySet.add(property);
      _willDelayInterval = delay;
    }
  }

  /// Payload Format Indicator
  ///
  /// False indicates that the Will Message is unspecified bytes, which is equivalent
  /// to not sending a Payload Format Indicator.
  /// True indicates that the Will Message is UTF-8 Encoded Character Data.
  ///  The broker MAY validate that the Will Message is of the format indicated,
  ///  and if it is not send a Connect Acknowledgement message [MqttConnectAckMessage]
  ///  with the Reason Code of 0x99 (Payload format invalid).
  bool _payloadFormatIndicator = false;
  bool get payloadFormatIndicator => _payloadFormatIndicator;
  set payloadFormatIndicator(bool indicator) {
    final property =
        MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
    property.value = indicator ? 1 : 0;
    _propertySet.add(property);
    _payloadFormatIndicator = indicator;
  }

  /// Message Expiry Interval
  ///
  ///  The value is the lifetime of the Will Message in seconds and is sent as the
  ///  Publication Expiry Interval when the broker publishes the Will Message.
  ///  If absent(value = 0), no Message Expiry Interval is sent when the broker
  ///  publishes the Will Message.
  int _messageExpiryInterval = 0;
  int get messageExpiryInterval => _messageExpiryInterval;
  set messageExpiryInterval(int interval) {
    if (interval != 0) {
      final property = MqttFourByteIntegerProperty(
          MqttPropertyIdentifier.messageExpiryInterval);
      property.value = interval;
      _propertySet.add(property);
      _messageExpiryInterval = interval;
    }
  }

  /// Content Type
  ///
  /// The value of the Content Type is defined by the sending and
  /// receiving application.
  String? _contentType;
  String? get contentType => _contentType;
  set contentType(String? type) {
    if (type != null) {
      final property =
          MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
      property.value = type;
      _propertySet.add(property);
      _contentType = type;
    }
  }

  /// Response Topic
  ///
  /// The Topic Name for a response message. The presence of a Response Topic
  /// identifies the Will Message as a Request.
  String? _responseTopic;
  String? get responseTopic => _responseTopic;
  set responseTopic(String? topic) {
    if (topic != null) {
      final property =
          MqttUtf8StringProperty(MqttPropertyIdentifier.responseTopic);
      property.value = topic;
      _propertySet.add(property);
      _responseTopic = topic;
    }
  }

  /// Correlation Data
  ///
  ///  The Correlation Data is used by the sender of the Request Message
  ///  to identify which request the Response Message is for when
  ///  it is received.
  ///  If the Correlation Data is not present, the Requester does not require
  ///  any correlation data.
  ///  The value of the Correlation Data only has meaning to the sender of the
  ///  Request Message and receiver of the Response Message.
  typed.Uint8Buffer? _correlationData;
  typed.Uint8Buffer? get correlationData => _correlationData;
  set correlationData(typed.Uint8Buffer? data) {
    if (data != null) {
      final property =
          MqttBinaryDataProperty(MqttPropertyIdentifier.correlationdata);
      property.addBytes(data);
      _propertySet.add(property);
      if (_correlationData == null) {
        _correlationData = typed.Uint8Buffer()..addAll(data);
      } else {
        _correlationData!.clear();
        _correlationData!.addAll(data);
      }
    }
  }

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  final _userProperties = <MqttUserProperty>[];
  List<MqttUserProperty> get userProperties => _userProperties;
  set userProperties(List<MqttUserProperty> properties) {
    for (var userProperty in properties) {
      _propertySet.add(userProperty);
      _userProperties.addAll(properties);
    }
  }

  /// Write to a message stream
  void writeTo(MqttByteBuffer stream) => _propertySet.writeTo(stream);

  /// Write length
  int getWriteLength() => _propertySet.getWriteLength();

  /// Length of the properties
  int get length => _propertySet.length();

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Will Delay Interval = $_willDelayInterval');
    sb.writeln('Payload Format Indicator = $_payloadFormatIndicator');
    sb.writeln('Message Expiry Interval = $_messageExpiryInterval');
    sb.writeln('Content Type = $_contentType');
    sb.writeln('Response Topic = $_responseTopic');
    sb.writeln('Correlation Data = $_correlationData');
    sb.writeln('user properties = ${_propertySet.toString()}');
    return sb.toString();
  }
}
