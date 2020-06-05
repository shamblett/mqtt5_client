/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Implementation of the variable header for an MQTT Publish message.
/// The Variable Header of the Publish message contains the following fields in the
/// order: Topic Name, Packet Identifier, and Properties.
class MqttPublishVariableHeader implements MqttIVariableHeader {
  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader(this.header);

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader.fromByteBuffer(
      this.header, MqttByteBuffer variableHeaderStream) {
    readFrom(variableHeaderStream);
  }

  /// Standard header
  MqttHeader header;

  /// Length
  @override
  int length = 0;

  /// Topic name
  String topicName = '';

  /// Message identifier
  int messageIdentifier = 0;

  /// Properties
  final _propertySet = MqttPropertyContainer();

  /// Encoder
  final MqttUtf8Encoding _enc = MqttUtf8Encoding();

  /// Payload Format Indicator
  ///
  /// false indicates that the Payload is unspecified bytes, which is equivalent to
  /// not sending a Payload Format Indicator.
  /// True indicates that the Payload is UTF-8 Encoded Character Data.
  bool _payloadFormatIndicator = false;
  bool get payloadFormatIndicator => _payloadFormatIndicator;
  set payloadFormatIndicator(bool indicator) {
    var property =
        MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
    property.value = indicator ? 1 : 0;
    _propertySet.add(property);
    _payloadFormatIndicator = indicator;
  }

  /// Message Expiry Interval
  ///
  ///  The lifetime of the Application Message in seconds.
  ///  If absent, the Application Message does not expire.
  int _messageExpiryInterval = 65535;
  int get messageExpiryInterval => _messageExpiryInterval;
  set messageExpiryInterval(int interval) {
    var property = MqttFourByteIntegerProperty(
        MqttPropertyIdentifier.messageExpiryInterval);
    property.value = interval;
    _propertySet.add(property);
    _messageExpiryInterval = interval;
  }

  /// Topic Alias
  ///
  /// A Topic Alias is an integer value that is used to identify the Topic instead of
  /// using the Topic Name.
  /// Topic Alias mappings exist only within a Network Connection and last only for
  /// the lifetime of that Network Connection.
  /// A Topic Alias of 0 is not permitted.
  int _topicAlias = 255;
  int get topicAlias => _topicAlias;
  set topicAlias(int maximum) {
    if (maximum == 0) {
      throw ArgumentError(
          'MqttPublishVariableHeader::topicAlias - 0 is not a valid value');
    }
    var property =
        MqttTwoByteIntegerProperty(MqttPropertyIdentifier.topicAliasMaximum);
    property.value = maximum;
    _propertySet.add(property);
    _topicAlias = maximum;
  }

  /// Response Topic
  ///
  /// The Topic Name for a response message.
  /// The Response Topic MUST NOT contain wildcard characters.
  String _responseTopic = '';
  String get responseTopic => _responseTopic;
  set responseTopic(String topic) {
    // Validate the response topic
    try {
      MqttPublicationTopic(topic);
    } on Exception {
      throw ArgumentError(
          'MqttPublishVariableHeader::responseTopic topic cannot contain wildcards');
    }
    var property = MqttUtf8StringProperty(MqttPropertyIdentifier.responseTopic);
    property.value = topic;
    _propertySet.add(property);
    _responseTopic = topic;
  }

  /// Correlation Data
  ///
  ///  The Correlation Data is used by the sender of the Request Message
  ///  to identify which request the Response Message is for when it is
  ///  received.
  typed.Uint8Buffer _correlationData;
  typed.Uint8Buffer get correlationData => _correlationData;
  set correlationData(typed.Uint8Buffer data) {
    final property =
        MqttBinaryDataProperty(MqttPropertyIdentifier.correlationdata);
    property.addBytes(data);
    _propertySet.add(property);
    _correlationData = data;
  }

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  final _userProperties = <MqttStringPairProperty>[];
  List<MqttStringPairProperty> get userProperties => _userProperties;
  set userProperties(List<MqttStringPairProperty> properties) {
    for (var userProperty in properties) {
      userProperty.identifier = MqttPropertyIdentifier.userProperty;
      _propertySet.add(userProperty);
      _userProperties.addAll(properties);
    }
  }

  /// Subscription Identifier
  ///
  /// The Subscription Identifier can have the value of 1 to 268,435,455.
  /// Multiple Subscription Identifiers will be included in a received message if the
  /// publication is the result of a match to more than one subscription, in this case their
  /// order is not significant.
  final _subscriptionIdentifier = <int>[];
  List<int> get subscriptionIdentifier => _subscriptionIdentifier;
  set subscriptionIdentifier(identifier) {
    if (identifier < 1 || identifier > 268435455) {
      throw ArgumentError(
          'MqttPublishVariableHeader::subscriptionIdentifier identifier is invalid');
    }
    final property = MqttVariableByteIntegerProperty(
        MqttPropertyIdentifier.subscriptionIdentifier);
    property.value = identifier;
    _propertySet.add(property);
    _subscriptionIdentifier.add(identifier);
  }

  /// Content Type
  ///
  /// The value of the Content Type is defined by the sending and
  /// receiving application.
  String _contentType = '';
  String get contentType => _contentType;
  set contentType(String type) {
    final property = MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
    property.value = type;
    _propertySet.add(property);
    _contentType = type;
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readTopicName(variableHeaderStream);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      readMessageIdentifier(variableHeaderStream);
    }
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeTopicName(variableHeaderStream);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      writeMessageIdentifier(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    headerLength += _enc.byteCount(topicName);
    if (header.qos == MqttQos.atLeastOnce ||
        header.qos == MqttQos.exactlyOnce) {
      headerLength += 2;
    }
    return headerLength;
  }

  /// Topic name
  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    length += _enc.byteCount(topicName);
  }

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Topic name
  void writeTopicName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, topicName.toString());
  }

  /// Message identifier
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('TopicName = {$topicName}');
    sb.writeln('MessageIdentifier = {$messageIdentifier}');
    return sb.toString();
  }
}
