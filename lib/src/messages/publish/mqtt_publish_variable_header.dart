// ignore_for_file: no-magic-number

/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt5_client.dart';

/// The Variable Header of the Publish message contains the following fields in the
/// order: Topic Name, Packet Identifier, and Properties.
class MqttPublishVariableHeader implements MqttIVariableHeader {
  /// Standard header
  MqttHeader? header;

  /// Topic name
  String topicName = '';

  /// Message identifier
  int messageIdentifier = 0;

  int _length = 0;

  bool _payloadFormatIndicator = false;

  int? _messageExpiryInterval = 65535;

  int? _topicAlias = 255;

  String? _responseTopic = '';

  // Properties
  final _propertySet = MqttPropertyContainer();

  // Encoder
  final MqttUtf8Encoding _enc = MqttUtf8Encoding();

  typed.Uint8Buffer? _correlationData;

  List<MqttUserProperty> _userProperty = <MqttUserProperty>[];

  final _subscriptionIdentifier = <int?>[];

  String? _contentType = '';

  /// The length of the variable header as received.
  /// To get the write length use[getWriteLength].
  @override
  int get length => _length;

  /// Payload Format Indicator
  ///
  /// False indicates that the Payload is unspecified bytes, which is equivalent to
  /// not sending a Payload Format Indicator.
  /// True indicates that the Payload is UTF-8 Encoded Character Data.
  bool get payloadFormatIndicator => _payloadFormatIndicator;

  /// Message Expiry Interval
  ///
  ///  The lifetime of the Application Message in seconds.
  ///  If absent, the Application Message does not expire.
  int? get messageExpiryInterval => _messageExpiryInterval;

  /// Topic Alias
  ///
  /// A Topic Alias is an integer value that is used to identify the Topic instead of
  /// using the Topic Name.
  /// Topic Alias mappings exist only within a network connection and last only for
  /// the lifetime of that network connection.
  /// A Topic Alias of 0 is not permitted.
  int? get topicAlias => _topicAlias;

  /// Response Topic
  ///
  /// The Topic Name for a response message.
  /// The Response Topic MUST NOT contain wildcard characters.
  String? get responseTopic => _responseTopic;

  /// Correlation Data
  ///
  ///  The Correlation Data is used by the sender of the Request Message
  ///  to identify which request the Response Message is for when it is
  ///  received.
  typed.Uint8Buffer? get correlationData => _correlationData;

  /// User property
  ///
  /// The User Property is allowed to appear multiple times to represent
  /// multiple name, value pairs. The same name is allowed to appear
  /// more than once.
  List<MqttUserProperty> get userProperty => _userProperty;

  /// Subscription Identifier
  ///
  /// The Subscription Identifier can have the value of 1 to 268,435,455.
  /// Multiple Subscription Identifiers will be included in a received message if the
  /// publication is the result of a match to more than one subscription, in this case their
  /// order is not significant.
  List<int?> get subscriptionIdentifier => _subscriptionIdentifier;

  /// Content Type
  ///
  /// The value of the Content Type is defined by the sending and
  /// receiving application.
  String? get contentType => _contentType;

  set payloadFormatIndicator(bool indicator) {
    var property = MqttByteProperty(
      MqttPropertyIdentifier.payloadFormatIndicator,
    );
    property.value = indicator ? 1 : 0;
    _propertySet.add(property);
    _payloadFormatIndicator = indicator;
  }

  set messageExpiryInterval(int? interval) {
    var property = MqttFourByteIntegerProperty(
      MqttPropertyIdentifier.messageExpiryInterval,
    );
    property.value = interval;
    _propertySet.add(property);
    _messageExpiryInterval = interval;
  }

  set topicAlias(int? alias) {
    if (alias == 0) {
      throw ArgumentError(
        'MqttPublishVariableHeader::topicAlias - 0 is not a valid value',
      );
    }
    var property = MqttTwoByteIntegerProperty(
      MqttPropertyIdentifier.topicAlias,
    );
    property.value = alias;
    _propertySet.add(property);
    _topicAlias = alias;
  }

  set responseTopic(String? topic) {
    // Validate the response topic
    try {
      MqttPublicationTopic(topic);
    } on Exception catch (_, stack) {
      Error.throwWithStackTrace(
        ArgumentError(
          'MqttPublishVariableHeader::responseTopic topic cannot contain wildcards',
        ),
        stack,
      );
    }
    var property = MqttUtf8StringProperty(MqttPropertyIdentifier.responseTopic);
    property.value = topic;
    _propertySet.add(property);
    _responseTopic = topic;
  }

  set correlationData(typed.Uint8Buffer? data) {
    final property = MqttBinaryDataProperty(
      MqttPropertyIdentifier.correlationdata,
    );
    property.addBytes(data);
    _propertySet.add(property);
    _correlationData = data;
  }

  set userProperty(List<MqttUserProperty>? properties) {
    if (properties != null) {
      for (var userProperty in properties) {
        _propertySet.add(userProperty);
      }
      _userProperty.addAll(properties);
    }
  }

  set subscriptionIdentifier(identifier) {
    if (identifier < 1 || identifier > MqttConstants.maxMessageSize) {
      throw ArgumentError(
        'MqttPublishVariableHeader::subscriptionIdentifier identifier is invalid',
      );
    }
    final property = MqttVariableByteIntegerProperty(
      MqttPropertyIdentifier.subscriptionIdentifier,
    );
    property.value = identifier;
    _propertySet.add(property);
    _subscriptionIdentifier.add(identifier);
  }

  set contentType(String? type) {
    final property = MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
    property.value = type;
    _propertySet.add(property);
    _contentType = type;
  }

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader(this.header);

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader.fromByteBuffer(
    this.header,
    MqttByteBuffer variableHeaderStream,
  ) {
    readFrom(variableHeaderStream);
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readTopicName(variableHeaderStream);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      readMessageIdentifier(variableHeaderStream);
    }
    // Properties
    variableHeaderStream.shrink();
    _propertySet.readFrom(variableHeaderStream);
    _processProperties();
    variableHeaderStream.shrink();
    _length += _propertySet.getWriteLength();
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeTopicName(variableHeaderStream);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      writeMessageIdentifier(variableHeaderStream);
    }
    _propertySet.writeTo(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    headerLength += _enc.byteCount(topicName);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      headerLength += 2;
    }
    headerLength += _propertySet.getWriteLength();
    return headerLength;
  }

  /// Topic name
  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    final enc = MqttUtf8Encoding();
    _length = enc.length(enc.toUtf8(topicName)) + 2;
  }

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    _length += 2;
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
    sb.writeln('Topic Name = $topicName');
    sb.writeln('Message Identifier = $messageIdentifier');
    sb.writeln('Payload Format Indicator = $payloadFormatIndicator');
    sb.writeln('Message Expiry Interval = $messageExpiryInterval');
    sb.writeln('Topic Alias = $topicAlias');
    sb.writeln('Response Topic = $responseTopic');
    sb.writeln('Subscription Identifier(s) = $subscriptionIdentifier');
    sb.writeln('Properties = ${_propertySet.toString()}');
    return sb.toString();
  }

  void _processProperties() {
    if (!_propertySet.propertiesAreValid()) {
      throw FormatException(
        'MqttPublishVariableHeader::_processProperties, message properties received are invalid',
      );
    }
    final properties = _propertySet.toList();
    for (final property in properties) {
      switch (property.identifier) {
        case MqttPropertyIdentifier.payloadFormatIndicator:
          _payloadFormatIndicator = property.value == 1;
          break;
        case MqttPropertyIdentifier.messageExpiryInterval:
          _messageExpiryInterval = property.value;
          break;
        case MqttPropertyIdentifier.topicAlias:
          _topicAlias = property.value;
          break;
        case MqttPropertyIdentifier.responseTopic:
          _responseTopic = property.value;
          break;
        case MqttPropertyIdentifier.correlationdata:
          _correlationData = property.value;
          break;
        case MqttPropertyIdentifier.subscriptionIdentifier:
          _subscriptionIdentifier.add(property.value);
          break;
        case MqttPropertyIdentifier.contentType:
          _contentType = property.value;
          break;
        default:
          if (property.identifier != MqttPropertyIdentifier.userProperty) {
            MqttLogger.log(
              'MqttPublishVariableHeader::_processProperties, unexpected property type'
              'received, identifier is ${property.identifier}, ignoring',
            );
          }
      }
      _userProperty = _propertySet.userProperties;
    }
  }
}
