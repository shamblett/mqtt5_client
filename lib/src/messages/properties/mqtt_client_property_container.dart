/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// A property container for use in MQTT Messages
class MqttPropertyContainer {
  // The container can only contain one entry of each property type
  final _container = <MqttPropertyIdentifier, MqttIProperty>{};

  final _enc = MqttVariableByteIntegerEncoding();

  /// Add a property.
  /// Note that the container will hold the last added property of any type
  void add(MqttIProperty property) =>
      _container[property.identifier] = property;

  /// Delete a property.
  /// Returns true if the property was deleted, false if the property didn't
  /// already exist
  bool delete(MqttPropertyIdentifier identifier) =>
      _container.remove(identifier) != null;

  /// Clear
  void clear() => _container.clear();

  /// Contains
  bool contains(MqttPropertyIdentifier identifier) =>
      _container.containsKey(identifier);

  /// Number of properties
  int get count => _container.length;

  /// To byte buffer
  /// Complete serialization of the properties including the property length bytes
  typed.Uint8Buffer serialize() {
    final buffer = typed.Uint8Buffer();
    final stream = MqttByteBuffer(buffer);
    // Empty check
    if (_container.isEmpty) {
      return _enc.fromInt(0);
    }
    for (var property in _container.values) {
      property.writeTo(stream);
    }
    final length = stream.length;
    final out = _enc.fromInt(length);
    return out..addAll(stream.buffer);
  }

  /// Length of the serialized properties including the length bytes
  int getWriteLength() => serialize().length;

  // Length of the serialized properties themselves.
  int length() => _enc.toInt(serialize());

  /// Serialize to a byte buffer stream including the length
  void writeTo(MqttByteBuffer stream) {
    final buffer = serialize();
    stream.write(buffer);
  }

  /// Deserialize from a byte buffer stream
  /// The stream must be positioned at the start of the message properties, i.e.
  /// on the length bytes.
  void readFrom(MqttByteBuffer stream) {
    // Get the length of the properties
    var length = _enc.toInt(stream.buffer);
    // Read the encoded byte length of the actual property set length
    // from the stream.
    stream.read(_enc.length(length));

    // Build the property set until we run out of them
    while (length != 0) {
      final property = MqttPropertyFactory.get(stream);
      _container[property.identifier] = property;
      length -= property.getWriteLength();
    }
  }

  /// Check the property set is valid, i.e doesn't contain any not set
  /// identifiers. An empty container of properties is valid.
  bool propertiesAreValid() =>
      !_container.containsKey(MqttPropertyIdentifier.notSet);

  /// To list
  List<MqttIProperty> toList() => _container.values.toList();

  @override
  String toString() {
    final sb = StringBuffer();
    for (var property in _container.values) {
      sb.writeln(property);
    }
    return sb.toString();
  }
}
