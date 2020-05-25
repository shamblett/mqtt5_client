/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
import 'package:mqtt5_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

@TestOn('vm')

/// Helper methods for test message serialization and deserialization
class MessageSerializationHelper {
  /// Invokes the serialization of a message to get an array of bytes that represent the message.
  static typed.Uint8Buffer getMessageBytes(MqttMessage msg) {
    final buff = typed.Uint8Buffer();
    final ms = MqttByteBuffer(buff);
    msg.writeTo(ms);
    ms.seek(0);
    final msgBytes = ms.read(ms.length);
    return msgBytes;
  }
}

void main() {
  group('Header', () {
    /// Test helper method to call Get Remaining Bytes with a specific value
    typed.Uint8Buffer callGetRemainingBytesWithValue(int value) {
      // validates a payload size of a single byte using the example values supplied in the MQTT spec
      final header = MqttHeader();
      header.messageSize = value;
      return header.getRemainingLengthBytes();
    }

    /// Creates byte array header with a single byte length
    /// byte1 - the first header byte
    /// length - the length byte
    typed.Uint8Buffer getHeaderBytes(int byte1, int length) {
      final tmp = typed.Uint8Buffer(2);
      tmp[0] = byte1;
      tmp[1] = length;
      return tmp;
    }

    /// Gets the MQTT header from a byte arrayed header.
    MqttHeader getMqttHeader(typed.Uint8Buffer headerBytes) {
      final buff = MqttByteBuffer(headerBytes);
      return MqttHeader.fromByteBuffer(buff);
    }

    test('Single byte payload size', () {
      // Validates a payload size of a single byte using the example values supplied in the MQTT spec
      final returnedBytes = callGetRemainingBytesWithValue(127);
      // Check that the count of bytes returned is only 1, and the value of the byte is correct.
      expect(returnedBytes.length, 1);
      expect(returnedBytes[0], 127);
    });
    test('Double byte payload size lower boundary 128', () {
      final returnedBytes = callGetRemainingBytesWithValue(128);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x01);
    });
    test('Double byte payload size upper boundary 16383', () {
      final returnedBytes = callGetRemainingBytesWithValue(16383);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0x7F);
    });
    test('Triple byte payload size lower boundary 16384', () {
      final returnedBytes = callGetRemainingBytesWithValue(16384);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x01);
    });
    test('Triple byte payload size upper boundary 2097151', () {
      final returnedBytes = callGetRemainingBytesWithValue(2097151);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0x7F);
    });
    test('Quadruple byte payload size lower boundary 2097152', () {
      final returnedBytes = callGetRemainingBytesWithValue(2097152);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x80);
      expect(returnedBytes[3], 0x01);
    });
    test('Quadruple byte payload size upper boundary 268435455', () {
      final returnedBytes = callGetRemainingBytesWithValue(268435455);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0xFF);
      expect(returnedBytes[3], 0x7F);
    });
    test('Payload size out of upper range', () {
      final header = MqttHeader();
      var raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = 268435456;
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test('Payload size out of lower range', () {
      final header = MqttHeader();
      var raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = -1;
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test('Duplicate', () {
      final header = MqttHeader().isDuplicate();
      expect(header.duplicate, isTrue);
    });
    test('Qos', () {
      final header = MqttHeader().withQos(MqttQos.atMostOnce);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test('Message type', () {
      final header = MqttHeader().asType(MqttMessageType.publishComplete);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test('Retain', () {
      final header = MqttHeader().shouldBeRetained();
      expect(header.retain, isTrue);
    });
    test('Round trip', () {
      final inputHeader = MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 1;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      inputHeader.writeTo(1, buffer);
      buffer.reset();
      final outputHeader = MqttHeader.fromByteBuffer(buffer);
      expect(inputHeader.duplicate, outputHeader.duplicate);
      expect(inputHeader.retain, outputHeader.retain);
      expect(inputHeader.messageSize, outputHeader.messageSize);
      expect(inputHeader.messageType, outputHeader.messageType);
      expect(inputHeader.qos, outputHeader.qos);
    });
    test('Corrupt header', () {
      final inputHeader = MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 268435455;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      inputHeader.writeTo(268435455, buffer);
      // Fudge the header by making the last bit of the 4th message size byte a 1, therefore making the header
      // invalid because the last bit of the 4th size byte should always be 0 (according to the spec). It's how
      // we know to stop processing the header when reading a full message).
      buffer.seek(0);
      buffer.readByte();
      buffer.readByte();
      buffer.readByte();
      buffer.writeByte(buffer.readByte() | 0xFF);
      var raised = false;
      buffer.seek(0);
      try {
        final outputHeader = MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, true);
    });
    test('Corrupt header undersize', () {
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      buffer.writeByte(0);
      buffer.seek(0);
      var raised = false;
      try {
        final outputHeader = MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, true);
    });
    test('QOS at most once', () {
      final headerBytes = getHeaderBytes(1, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test('QOS at least once', () {
      final headerBytes = getHeaderBytes(2, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atLeastOnce);
    });
    test('QOS exactly once', () {
      final headerBytes = getHeaderBytes(4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.exactlyOnce);
    });
    test('QOS reserved1', () {
      final headerBytes = getHeaderBytes(6, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.reserved1);
    });
    test('Message type reserved1', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.reserved1);
    });
    test('Message type connect', () {
      final headerBytes = getHeaderBytes(1 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connect);
    });
    test('Message type connect ack', () {
      final headerBytes = getHeaderBytes(2 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connectAck);
    });
    test('Message type publish', () {
      final headerBytes = getHeaderBytes(3 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publish);
    });
    test('Message type publish ack', () {
      final headerBytes = getHeaderBytes(4 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishAck);
    });
    test('Message type publish received', () {
      final headerBytes = getHeaderBytes(5 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishReceived);
    });
    test('Message type publish release', () {
      final headerBytes = getHeaderBytes(6 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishRelease);
    });
    test('Message type publish complete', () {
      final headerBytes = getHeaderBytes(7 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test('Message type subscribe', () {
      final headerBytes = getHeaderBytes(8 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test('Message type subscribe ack', () {
      final headerBytes = getHeaderBytes(9 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribeAck);
    });
    test('Message type subscribe', () {
      final headerBytes = getHeaderBytes(8 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test('Message type unsubscribe', () {
      final headerBytes = getHeaderBytes(10 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribe);
    });
    test('Message type unsubscribe ack', () {
      final headerBytes = getHeaderBytes(11 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribeAck);
    });
    test('Message type ping request', () {
      final headerBytes = getHeaderBytes(12 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingRequest);
    });
    test('Message type ping response', () {
      final headerBytes = getHeaderBytes(13 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingResponse);
    });
    test('Message type disconnect', () {
      final headerBytes = getHeaderBytes(14 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.disconnect);
    });
    test('Message type auth', () {
      final headerBytes = getHeaderBytes(15 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.auth);
    });
    test('Duplicate true', () {
      final headerBytes = getHeaderBytes(8, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.duplicate, isTrue);
    });
    test('Duplicate false', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.duplicate, isFalse);
    });
    test('Retain true', () {
      final headerBytes = getHeaderBytes(1, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.retain, isTrue);
    });
    test('Retain false', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.retain, isFalse);
    });
  });

  group('Connect Flags', () {
    /// Gets the connect flags for a specific byte value
    MqttConnectFlags getConnectFlags(int value) {
      final tmp = typed.Uint8Buffer(1);
      tmp[0] = value;
      final buffer = MqttByteBuffer(tmp);
      return MqttConnectFlags.fromByteBuffer(buffer);
    }

    test('WillQos - AtMostOnce', () {
      expect(getConnectFlags(0).willQos, MqttQos.atMostOnce);
    });
    test('WillQos - AtLeastOnce', () {
      expect(getConnectFlags(8).willQos, MqttQos.atLeastOnce);
    });
    test('WillQos - ExactlyOnce', () {
      expect(getConnectFlags(16).willQos, MqttQos.exactlyOnce);
    });
    test('WillQos - Reserved1', () {
      expect(getConnectFlags(24).willQos, MqttQos.reserved1);
    });
    test('Passwordflag true', () {
      expect(getConnectFlags(64).passwordFlag, isTrue);
    });
    test('Passwordflag false', () {
      expect(getConnectFlags(0).passwordFlag, isFalse);
    });
    test('Usernameflag true', () {
      expect(getConnectFlags(128).usernameFlag, isTrue);
    });
    test('Usernameflag false', () {
      expect(getConnectFlags(0).usernameFlag, isFalse);
    });
    test('Cleanstart true', () {
      expect(getConnectFlags(2).cleanStart, isTrue);
    });
    test('Cleanstart false', () {
      expect(getConnectFlags(1).cleanStart, isFalse);
    });
    test('Willretain true', () {
      expect(getConnectFlags(32).willRetain, isTrue);
    });
    test('Willretain false', () {
      expect(getConnectFlags(1).willRetain, isFalse);
    });
    test('Willflag true', () {
      expect(getConnectFlags(4).willFlag, isTrue);
    });
    test('Willflag false', () {
      expect(getConnectFlags(1).willFlag, isFalse);
    });
  });

  group('Properties', () {
    test('Byte Property', () {
      final property = MqttByteProperty(MqttPropertyIdentifier.contentType);
      expect(property.getWriteLength(), 2);
      property.value = 0x60;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0x60);
      final property1 = MqttByteProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, 0x60);
      print(property1);
    });
    test('Four Byte Integer Property', () {
      final property =
          MqttFourByteIntegerProperty(MqttPropertyIdentifier.contentType);
      expect(property.getWriteLength(), 5);
      property.value = 0xdeadbeef;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0xde);
      expect(stream.readByte(), 0xad);
      expect(stream.readByte(), 0xbe);
      expect(stream.readByte(), 0xef);
      final property1 =
          MqttFourByteIntegerProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, 0xdeadbeef);
    });
    test('Two Byte Integer Property', () {
      final property =
          MqttTwoByteIntegerProperty(MqttPropertyIdentifier.contentType);
      expect(property.getWriteLength(), 3);
      property.value = 0xdead;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0xde);
      expect(stream.readByte(), 0xad);
      final property1 =
          MqttTwoByteIntegerProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, 0xdead);
    });
    test('Variable Byte Integer Property', () {
      final property =
          MqttVariableByteIntegerProperty(MqttPropertyIdentifier.contentType);
      expect(property.getWriteLength(), 5);
      property.value = 234881024;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0x80);
      expect(stream.readByte(), 0x80);
      expect(stream.readByte(), 0x80);
      expect(stream.readByte(), 0x70);
      final property1 =
          MqttVariableByteIntegerProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, 234881024);
    });
    test('Binary Data Property', () {
      final property =
          MqttBinaryDataProperty(MqttPropertyIdentifier.contentType);
      final buff = typed.Uint8Buffer();
      buff.addAll([1, 2, 3, 4, 5]);
      property.addBytes(buff);
      expect(property.getWriteLength(), 8);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0x00);
      expect(stream.readByte(), 0x05);
      expect(stream.readByte(), 0x01);
      expect(stream.readByte(), 0x02);
      expect(stream.readByte(), 0x03);
      expect(stream.readByte(), 0x04);
      expect(stream.readByte(), 0x05);
      final property1 = MqttBinaryDataProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value.toList(), [1, 2, 3, 4, 5]);
    });
    test('UTF8 String Property', () {
      final property =
          MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
      const value = 'Hello';
      property.value = value;
      expect(property.getWriteLength(), 8);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0x00);
      expect(stream.readByte(), 0x05);
      expect(stream.readByte(), 0x48);
      expect(stream.readByte(), 0x65);
      expect(stream.readByte(), 0x6c);
      expect(stream.readByte(), 0x6c);
      expect(stream.readByte(), 0x6f);
      final property1 = MqttUtf8StringProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, value);
    });
    test('String Pair Property', () {
      final property =
          MqttStringPairProperty(MqttPropertyIdentifier.contentType);
      property.pairName = 'Hello ';
      property.pairValue = 'World';
      expect(property.getWriteLength(), 16);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0x00);
      expect(stream.readByte(), 0x06);
      expect(stream.readByte(), 0x48);
      expect(stream.readByte(), 0x65);
      expect(stream.readByte(), 0x6c);
      expect(stream.readByte(), 0x6c);
      expect(stream.readByte(), 0x6f);
      expect(stream.readByte(), 0x20);
      expect(stream.readByte(), 0x00);
      expect(stream.readByte(), 0x05);
      expect(stream.readByte(), 0x57);
      expect(stream.readByte(), 0x6f);
      expect(stream.readByte(), 0x72);
      expect(stream.readByte(), 0x6c);
      expect(stream.readByte(), 0x64);
      final property1 = MqttStringPairProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.pairName, 'Hello ');
      expect(property1.pairValue, 'World');
    });
    group('Property Factory', () {
      test('Unknown Property', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x55);
        buffer.add(0x20);
        final property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier, MqttPropertyIdentifier.notSet);
      });
      test('Byte Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x01);
        buffer.add(0x20);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(
            property.identifier, MqttPropertyIdentifier.payloadFormatIndicator);
        buffer[0] = 0x17;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.requestProblemInformation);
        buffer[0] = 0x19;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.requestResponseInformation);
        buffer[0] = 0x24;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier, MqttPropertyIdentifier.maximumQos);
        buffer[0] = 0x25;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier, MqttPropertyIdentifier.retainAvailable);
        buffer[0] = 0x28;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.wildcardSubscriptionAvailable);
        buffer[0] = 0x29;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.subscriptionIdentifierAvailable);
        buffer[0] = 0x2a;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttByteProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.sharedSubscriptionAvailable);
      });
      test('Four Byte Integer Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x02);
        buffer.add(0x80);
        buffer.add(0x80);
        buffer.add(0x80);
        buffer.add(0x70);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttFourByteIntegerProperty>());
        expect(
            property.identifier, MqttPropertyIdentifier.messageExpiryInterval);
        buffer[0] = 0x11;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttFourByteIntegerProperty>());
        expect(
            property.identifier, MqttPropertyIdentifier.sessionExpiryInterval);
        buffer[0] = 0x18;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttFourByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.willDelayInterval);
        buffer[0] = 0x27;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttFourByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.maximumPacketSize);
      });
      test('UTF8 Encoded String Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x03);
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add(0x65);
        buffer.add(0x66);
        buffer.add(0x67);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier, MqttPropertyIdentifier.contentType);
        buffer[0] = 0x08;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier, MqttPropertyIdentifier.responseTopic);
        buffer[0] = 0x12;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier,
            MqttPropertyIdentifier.assignedClientIdentifier);
        buffer[0] = 0x15;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(
            property.identifier, MqttPropertyIdentifier.authenticationMethod);
        buffer[0] = 0x1a;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier, MqttPropertyIdentifier.responseInformation);
        buffer[0] = 0x1c;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier, MqttPropertyIdentifier.serverReference);
        buffer[0] = 0x1f;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttUtf8StringProperty>());
        expect(property.identifier, MqttPropertyIdentifier.reasonString);
      });
      test('Binary Data Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x09);
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add(0x65);
        buffer.add(0x66);
        buffer.add(0x67);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttBinaryDataProperty>());
        expect(property.identifier, MqttPropertyIdentifier.correlationdata);
        buffer[0] = 0x16;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttBinaryDataProperty>());
        expect(property.identifier, MqttPropertyIdentifier.authenticationData);
      });
      test('Variable Byte Integer Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x0b);
        buffer.add(0x80);
        buffer.add(0x80);
        buffer.add(0x80);
        buffer.add(0x70);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttVariableByteIntegerProperty>());
        expect(
            property.identifier, MqttPropertyIdentifier.subscriptionIdentifier);
      });
      test('Two Byte Integer Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x13);
        buffer.add(0x80);
        buffer.add(0x80);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttTwoByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.serverKeepAlive);
        buffer[0] = 0x21;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttTwoByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.receiveMaximum);
        buffer[0] = 0x22;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttTwoByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.topicAliasMaximum);
        buffer[0] = 0x23;
        stream.reset();
        property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttTwoByteIntegerProperty>());
        expect(property.identifier, MqttPropertyIdentifier.topicAlias);
      });
      test('String Pair Properties', () {
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add(0x65);
        buffer.add(0x66);
        buffer.add(0x67);
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add(0x65);
        buffer.add(0x66);
        buffer.add(0x67);
        var property = MqttPropertyFactory.get(stream);
        expect(property, isA<MqttStringPairProperty>());
        expect(property.identifier, MqttPropertyIdentifier.userProperty);
      });
    });
    group('Property Container', () {
      test('Add', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp =
            MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
        byteProp.value = 0x44;
        final userProperty1 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty1.pairName = 'First';
        userProperty1.pairValue = 'First Value';
        final userProperty2 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty2.pairName = 'Second';
        userProperty1.pairValue = 'Second Value';
        container.add(stringProp);
        container.add(byteProp);
        container.add(userProperty1);
        container.add(userProperty2);
        expect(container.count, 4);
        expect(container.propertiesAreValid(), true);
        final propertyList = container.toList();
        expect(propertyList[0].identifier, MqttPropertyIdentifier.contentType);
        expect(propertyList[1].identifier,
            MqttPropertyIdentifier.payloadFormatIndicator);
        expect(propertyList[2].identifier, MqttPropertyIdentifier.userProperty);
        expect(propertyList[3].identifier, MqttPropertyIdentifier.userProperty);
      });
      test('Add - Not Valid And Clear', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp = MqttByteProperty(MqttPropertyIdentifier.notSet);
        byteProp.value = 0x44;
        container.add(stringProp);
        container.add(byteProp);
        expect(container.count, 2);
        expect(container.propertiesAreValid(), false);
        container.clear();
        expect(container.count, 0);
      });
      test('Delete', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp =
            MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
        byteProp.value = 0x44;
        final userProperty1 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty1.pairName = 'First';
        userProperty1.pairValue = 'First Value';
        final userProperty2 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty2.pairName = 'Second';
        userProperty2.pairValue = 'Second Value';
        container.add(stringProp);
        container.add(byteProp);
        container.add(userProperty1);
        container.add(userProperty2);
        expect(container.count, 4);
        expect(container.propertiesAreValid(), true);
        expect(container.delete(stringProp), true);
        expect(container.count, 3);
        expect(container.delete(byteProp), true);
        expect(container.count, 2);
        expect(container.delete(userProperty1), true);
        expect(container.count, 1);
        expect(container.contains(userProperty2), isTrue);
        expect(container.contains(userProperty1), isFalse);
        expect(container.delete(byteProp), false);
      });
      test('Serialize', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp =
            MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
        byteProp.value = 0x44;
        container.add(stringProp);
        container.add(byteProp);
        expect(container.count, 2);
        expect(container.propertiesAreValid(), true);
        final buffer = container.serialize();
        expect(buffer.toList(),
            [0x0a, 0x3, 0x00, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x01, 0x44]);
        expect(container.getWriteLength(), 11);
        expect(container.length(), 10);
      });
      test('Serialize - User Properties', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp =
            MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
        byteProp.value = 0x44;
        final userProperty1 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty1.pairName = 'a';
        userProperty1.pairValue = 'b';
        final userProperty2 =
            MqttStringPairProperty(MqttPropertyIdentifier.userProperty);
        userProperty2.pairName = 'c';
        userProperty2.pairValue = 'd';
        container.add(stringProp);
        container.add(byteProp);
        container.add(userProperty1);
        container.add(userProperty2);
        expect(container.count, 4);
        expect(container.propertiesAreValid(), true);
        final buffer = container.serialize();
        expect(buffer.toList(), [
          0x18,
          0x3,
          0x00,
          0x05,
          0x48,
          0x65,
          0x6c,
          0x6c,
          0x6f,
          0x01,
          0x44,
          0x26,
          0x00,
          0x01,
          0x61,
          0x00,
          0x01,
          0x62,
          0x26,
          0x00,
          0x01,
          0x63,
          0x00,
          0x01,
          0x64
        ]);
        expect(container.getWriteLength(), 25);
        expect(container.length(), 24);
      });
      test('Write To', () {
        final container = MqttPropertyContainer();
        final stringProp =
            MqttUtf8StringProperty(MqttPropertyIdentifier.contentType);
        stringProp.value = 'Hello';
        final byteProp =
            MqttByteProperty(MqttPropertyIdentifier.payloadFormatIndicator);
        byteProp.value = 0x44;
        container.add(stringProp);
        container.add(byteProp);
        expect(container.count, 2);
        expect(container.propertiesAreValid(), true);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        container.writeTo(stream);
        expect(stream.buffer.toList(),
            [0x0a, 0x3, 0x00, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x01, 0x44]);
      });
      test('Read From', () {
        final container = MqttPropertyContainer();
        final buffer = typed.Uint8Buffer()
          ..addAll([
            0x0a,
            0x3,
            0x00,
            0x05,
            0x48,
            0x65,
            0x6c,
            0x6c,
            0x6f,
            0x01,
            0x44
          ]);
        final stream = MqttByteBuffer(buffer);
        container.readFrom(stream);
        expect(container.count, 2);
        expect(container.propertiesAreValid(), true);
        final propList = container.toList();
        expect(propList[0], isA<MqttUtf8StringProperty>());
        expect(propList[1], isA<MqttByteProperty>());
        expect(propList[0].identifier, MqttPropertyIdentifier.contentType);
        expect(propList[0].value, 'Hello');
        expect(propList[1].identifier,
            MqttPropertyIdentifier.payloadFormatIndicator);
        expect(propList[1].value, 0x44);
      });
      test('Read From - User Properties', () {
        final container = MqttPropertyContainer();
        final buffer = typed.Uint8Buffer()
          ..addAll([
            0x18,
            0x3,
            0x00,
            0x05,
            0x48,
            0x65,
            0x6c,
            0x6c,
            0x6f,
            0x01,
            0x44,
            0x26,
            0x00,
            0x01,
            0x61,
            0x00,
            0x01,
            0x62,
            0x26,
            0x00,
            0x01,
            0x63,
            0x00,
            0x01,
            0x64
          ]);
        final stream = MqttByteBuffer(buffer);
        container.readFrom(stream);
        expect(container.count, 4);
        expect(container.propertiesAreValid(), true);
        final propList = container.toList();
        expect(propList[0], isA<MqttUtf8StringProperty>());
        expect(propList[1], isA<MqttByteProperty>());
        expect(propList[2], isA<MqttStringPairProperty>());
        expect(propList[3], isA<MqttStringPairProperty>());
        expect(propList[0].identifier, MqttPropertyIdentifier.contentType);
        expect(propList[0].value, 'Hello');
        expect(propList[1].identifier,
            MqttPropertyIdentifier.payloadFormatIndicator);
        expect(propList[1].value, 0x44);
        expect(propList[2].identifier, MqttPropertyIdentifier.userProperty);
        expect(propList[2].value.name, 'a');
        expect(propList[2].value.value, 'b');
        expect(propList[3].identifier, MqttPropertyIdentifier.userProperty);
        expect(propList[3].value.name, 'c');
        expect(propList[3].value.value, 'd');
      });
    });
  });

  group('Variable Headers', () {
    test('Variable Header Connect - No User Properties', () {
      final variableHeader = MqttConnectVariableHeader();
      final connectFlags = MqttConnectFlags();
      connectFlags.passwordFlag = true;
      connectFlags.willRetain = true;
      connectFlags.usernameFlag = true;
      connectFlags.willQos = MqttQos.exactlyOnce;
      variableHeader.connectFlags = connectFlags;
      variableHeader.keepAlive = 0x10;
      variableHeader.receiveMaximum = 0x20;
      variableHeader.authenticationMethod = 'AuthenticationMethod';
      variableHeader.requestProblemInformation = false;
      variableHeader.topicAliasMaximum = 0x30;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      variableHeader.writeTo(stream);
      expect(variableHeader.getWriteLength(), 42);
      expect(stream.buffer, [
        0,
        4,
        77,
        81,
        84,
        84,
        5,
        240,
        0,
        16,
        31,
        33,
        0,
        32,
        21,
        0,
        20,
        65,
        117,
        116,
        104,
        101,
        110,
        116,
        105,
        99,
        97,
        116,
        105,
        111,
        110,
        77,
        101,
        116,
        104,
        111,
        100,
        23,
        0,
        34,
        0,
        48
      ]);
      expect(variableHeader.connectFlags.passwordFlag, isTrue);
      expect(variableHeader.connectFlags.willRetain, isTrue);
      expect(variableHeader.connectFlags.willQos, MqttQos.exactlyOnce);
      expect(variableHeader.connectFlags.passwordFlag, isTrue);
      expect(variableHeader.keepAlive, 0x10);
      expect(variableHeader.receiveMaximum, 0x20);
      expect(variableHeader.authenticationMethod, 'AuthenticationMethod');
      expect(variableHeader.requestProblemInformation, false);
      expect(variableHeader.topicAliasMaximum, 0x30);
    });
    test('Variable Header Connect - User Properties', () {
      final variableHeader = MqttConnectVariableHeader();
      variableHeader.sessionExpiryInterval = 0x20;
      variableHeader.maximumPacketSize = 0x30;
      variableHeader.requestResponseInformation = true;
      var buffer = typed.Uint8Buffer();
      buffer.addAll([1, 2, 3, 4]);
      variableHeader.authenticationData = buffer;
      var property1 = MqttStringPairProperty();
      property1.pairName = 'Prop1';
      property1.pairValue = 'Prop1Value';
      var property2 = MqttStringPairProperty();
      property2.pairName = 'Prop2';
      property2.pairValue = 'Prop2Value';
      variableHeader.userProperties = [property1, property2];
      final streamBuffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(streamBuffer);
      variableHeader.writeTo(stream);
      expect(variableHeader.getWriteLength(), 70);
      expect(stream.buffer, [
        0,
        4,
        77,
        81,
        84,
        84,
        5,
        0,
        0,
        0,
        59,
        17,
        0,
        0,
        0,
        32,
        39,
        0,
        0,
        0,
        48,
        25,
        1,
        22,
        0,
        4,
        1,
        2,
        3,
        4,
        38,
        0,
        5,
        80,
        114,
        111,
        112,
        49,
        0,
        10,
        80,
        114,
        111,
        112,
        49,
        86,
        97,
        108,
        117,
        101,
        38,
        0,
        5,
        80,
        114,
        111,
        112,
        50,
        0,
        10,
        80,
        114,
        111,
        112,
        50,
        86,
        97,
        108,
        117,
        101
      ]);
      expect(variableHeader.sessionExpiryInterval, 0x20);
      expect(variableHeader.authenticationData.toList(), [1, 2, 3, 4]);
      expect(variableHeader.requestResponseInformation, true);
      expect(variableHeader.maximumPacketSize, 0x30);
      expect(variableHeader.userProperties[0], property1);
      expect(variableHeader.userProperties[1], property2);
    });
  });

  group('Payload', () {
    group('Connect Message', () {
      test('Will Properties - Empty', () {
        final willProperties = MqttWillProperties();
        expect(willProperties.responseTopic, isNull);
        expect(willProperties.messageExpiryInterval, 0);
        expect(willProperties.payloadFormatIndicator, isFalse);
        expect(willProperties.willDelayInterval, 0);
        expect(willProperties.contentType, isNull);
        expect(willProperties.correlationData, isNull);
        expect(willProperties.userProperties, isEmpty);
        expect(willProperties.getWriteLength(), 1);
        expect(willProperties.length, 0);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        willProperties.writeTo(stream);
        expect(stream.length, 1);
        expect(stream.buffer[0], 0);
        expect(stream.position, 1);
      });
      test('Will Properties - Complete', () {
        final willProperties = MqttWillProperties();
        willProperties.responseTopic = 'Response Topic';
        expect(willProperties.responseTopic, 'Response Topic');
        willProperties.messageExpiryInterval = 10;
        expect(willProperties.messageExpiryInterval, 10);
        willProperties.payloadFormatIndicator = true;
        expect(willProperties.payloadFormatIndicator, isTrue);
        willProperties.willDelayInterval = 30;
        expect(willProperties.willDelayInterval, 30);
        willProperties.contentType = 'Content Type';
        expect(willProperties.contentType, 'Content Type');
        final correlationdata = typed.Uint8Buffer()..addAll([1, 2, 3, 4]);
        willProperties.correlationData = correlationdata;
        expect(willProperties.correlationData.toList(), [1, 2, 3, 4]);
        final user1 = MqttStringPairProperty()
          ..pairName = 'name'
          ..pairValue = 'value';
        willProperties.userProperties = <MqttStringPairProperty>[user1];
        expect(willProperties.userProperties, isNotEmpty);
        expect(willProperties.userProperties[0], user1);
        expect(willProperties.getWriteLength(), 63);
        expect(willProperties.length, 62);
      });
    });
  });

  group('Messages', () {
    group('Connect', () {
      test('Basic serialization', () {
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(40)
            .startClean();
        print('Connect - Basic serialization::${msg.toString()}');
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        // VH will = 12, Msg = 6
        expect(mb[1], 0x12);
      });
      test('With will set', () {
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(30)
            .startClean()
            .will()
            .withWillQos(MqttQos.atLeastOnce)
            .withWillRetain()
            .withWillTopic('willTopic')
            .withWillMessage('willMessage');
        print('Connect - With will set::${msg.toString()}');
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        // VH will = 12, Msg = 6
        expect(mb[1], 0x2A);
      });
    });

    group('Connect Ack', () {
      test('Deserialisation - Connection accepted', () {
        // Our test deserialization message, with the following properties. Note this message is not
        // yet a real MQTT message, because not everything is implemented, but it must be modified
        // and amended as work progresses
        //
        // Message Specs________________
        // <20><02><00><00>
        final sampleMessage = typed.Uint8Buffer(4);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x02;
        sampleMessage[2] = 0x0;
        sampleMessage[3] = 0x0;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Connect Ack - Connection accepted::${baseMessage.toString()}');
        // Check that the message was correctly identified as a connect ack message.
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final MqttConnectAckMessage message = baseMessage;
        // Validate the message deserialization
        expect(
          message.header.duplicate,
          false,
        );
        expect(
          message.header.retain,
          false,
        );
        expect(message.header.qos, MqttQos.atMostOnce);
        expect(message.header.messageType, MqttMessageType.connectAck);
        expect(message.header.messageSize, 2);
        // Validate the variable header
        expect(message.variableHeader.returnCode,
            MqttConnectReturnCode.connectionAccepted);
      });
      test('Deserialisation - Unacceptable protocol version', () {
        // Our test deserialization message, with the following properties. Note this message is not
        // yet a real MQTT message, because not everything is implemented, but it must be modified
        // and amended as work progresses
        //
        // Message Specs________________
        // <20><02><00><00>
        final sampleMessage = typed.Uint8Buffer(4);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x02;
        sampleMessage[2] = 0x0;
        sampleMessage[3] = 0x1;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Connect Ack - Unacceptable protocol version::${baseMessage.toString()}');
        // Check that the message was correctly identified as a connect ack message.
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final MqttConnectAckMessage message = baseMessage;
        // Validate the message deserialization
        expect(
          message.header.duplicate,
          false,
        );
        expect(
          message.header.retain,
          false,
        );
        expect(message.header.qos, MqttQos.atMostOnce);
        expect(message.header.messageType, MqttMessageType.connectAck);
        expect(message.header.messageSize, 2);
        // Validate the variable header
        expect(message.variableHeader.returnCode,
            MqttConnectReturnCode.unacceptedProtocolVersion);
      });
      test('Deserialisation - Identifier rejected', () {
        // Our test deserialization message, with the following properties. Note this message is not
        // yet a real MQTT message, because not everything is implemented, but it must be modified
        // and amended as work progresses
        //
        // Message Specs________________
        // <20><02><00><00>
        final sampleMessage = typed.Uint8Buffer(4);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x02;
        sampleMessage[2] = 0x0;
        sampleMessage[3] = 0x2;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Connect Ack - Identifier rejected::${baseMessage.toString()}');
        // Check that the message was correctly identified as a connect ack message.
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final MqttConnectAckMessage message = baseMessage;
        // Validate the message deserialization
        expect(
          message.header.duplicate,
          false,
        );
        expect(
          message.header.retain,
          false,
        );
        expect(message.header.qos, MqttQos.atMostOnce);
        expect(message.header.messageType, MqttMessageType.connectAck);
        expect(message.header.messageSize, 2);
        // Validate the variable header
        expect(message.variableHeader.returnCode,
            MqttConnectReturnCode.identifierRejected);
      });
      test('Deserialisation - Broker unavailable', () {
        // Our test deserialization message, with the following properties. Note this message is not
        // yet a real MQTT message, because not everything is implemented, but it must be modified
        // and amended as work progresses
        //
        // Message Specs________________
        // <20><02><00><00>
        final sampleMessage = typed.Uint8Buffer(4);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x02;
        sampleMessage[2] = 0x0;
        sampleMessage[3] = 0x3;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Connect Ack - Broker unavailable::${baseMessage.toString()}');
        // Check that the message was correctly identified as a connect ack message.
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final MqttConnectAckMessage message = baseMessage;
        // Validate the message deserialization
        expect(
          message.header.duplicate,
          false,
        );
        expect(
          message.header.retain,
          false,
        );
        expect(message.header.qos, MqttQos.atMostOnce);
        expect(message.header.messageType, MqttMessageType.connectAck);
        expect(message.header.messageSize, 2);
        // Validate the variable header
        expect(message.variableHeader.returnCode,
            MqttConnectReturnCode.brokerUnavailable);
      });
    });
    test('Serialisation - Connection accepted', () {
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x20;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x0;
      final msg = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.connectionAccepted);
      print('Connect Ack - Connection accepted::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // connect ack - compression? always empty
      expect(actual[3], expected[3]); // return code.
    });
    test('Serialisation - Unacceptable protocol version', () {
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x20;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x1;
      final msg = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.unacceptedProtocolVersion);
      print('Connect Ack - Unacceptable protocol version::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // connect ack - compression? always empty
      expect(actual[3], expected[3]); // return code.
    });
    test('Serialisation - Identifier rejected', () {
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x20;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x2;
      final msg = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.identifierRejected);
      print('Connect Ack - Identifier rejected::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // connect ack - compression? always empty
      expect(actual[3], expected[3]); // return code.
    });
    test('Serialisation - Broker unavailable', () {
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x20;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x3;
      final msg = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.brokerUnavailable);
      print('Connect Ack - Broker unavailable::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // connect ack - compression? always empty
      expect(actual[3], expected[3]); // return code.
    });

    group('Disconnect', () {
      test('Deserialisation', () {
        final sampleMessage = typed.Uint8Buffer(2);
        sampleMessage[0] = 0xE0;
        sampleMessage[1] = 0x0;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Disconnect  - Deserialisation::${baseMessage.toString()}');
        // Check that the message was correctly identified as a disconnect message.
        expect(baseMessage, const TypeMatcher<MqttDisconnectMessage>());
      });
      test('Serialisation', () {
        final expected = typed.Uint8Buffer(2);
        expected[0] = 0xE0;
        expected[1] = 0x00;
        final msg = MqttDisconnectMessage();
        print('Disconnect - Serialisation::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]);
        expect(actual[1], expected[1]);
      });
    });

    group('Ping Request', () {
      test('Deserialisation', () {
        final sampleMessage = typed.Uint8Buffer(2);
        sampleMessage[0] = 0xC0;
        sampleMessage[1] = 0x0;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Ping Request  - Deserialisation::${baseMessage.toString()}');
        // Check that the message was correctly identified as a ping request message.
        expect(baseMessage, const TypeMatcher<MqttPingRequestMessage>());
      });
      test('Serialisation', () {
        final expected = typed.Uint8Buffer(2);
        expected[0] = 0xC0;
        expected[1] = 0x00;
        final msg = MqttPingRequestMessage();
        print('Ping Request - Serialisation::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]);
        expect(actual[1], expected[1]);
      });
    });

    group('Ping Response', () {
      test('Deserialisation', () {
        final sampleMessage = typed.Uint8Buffer(2);
        sampleMessage[0] = 0xD0;
        sampleMessage[1] = 0x00;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Ping Response  - Deserialisation::${baseMessage.toString()}');
        // Check that the message was correctly identified as a ping response message.
        expect(baseMessage, const TypeMatcher<MqttPingResponseMessage>());
      });
      test('Serialisation', () {
        final expected = typed.Uint8Buffer(2);
        expected[0] = 0xD0;
        expected[1] = 0x00;
        final msg = MqttPingResponseMessage();
        print('Ping Response - Serialisation::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]);
        expect(actual[1], expected[1]);
      });
    });

    group('Publish', () {
      test('Deserialisation - Valid payload', () {
        // Tests basic message deserialization from a raw byte array.
        // Message Specs________________
        // <30><0C><00><04>fredhello!
        final sampleMessage = <int>[
          0x30,
          0x0C,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish message.
        expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.duplicate, isFalse);
        expect(baseMessage.header.retain, isFalse);
        expect(baseMessage.header.qos, MqttQos.atMostOnce);
        expect(baseMessage.header.messageType, MqttMessageType.publish);
        expect(baseMessage.header.messageSize, 12);
        final MqttPublishMessage pm = baseMessage;
        // Check the payload
        expect(pm.payload.message[0], 'h'.codeUnitAt(0));
        expect(pm.payload.message[1], 'e'.codeUnitAt(0));
        expect(pm.payload.message[2], 'l'.codeUnitAt(0));
        expect(pm.payload.message[3], 'l'.codeUnitAt(0));
        expect(pm.payload.message[4], 'o'.codeUnitAt(0));
        expect(pm.payload.message[5], '!'.codeUnitAt(0));
      });
      test('Deserialisation - Valid payload V311', () {
        // Tests basic message deserialization from a raw byte array.
        // Message Specs________________
        // <30><0C><00><04>fredhello!
        final sampleMessage = <int>[
          0x30,
          0x0C,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        MqttClientProtocol.version = MqttClientConstants.mqttProtocolVersion;
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish message.
        expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.duplicate, isFalse);
        expect(baseMessage.header.retain, isFalse);
        expect(baseMessage.header.qos, MqttQos.atMostOnce);
        expect(baseMessage.header.messageType, MqttMessageType.publish);
        expect(baseMessage.header.messageSize, 12);
        final MqttPublishMessage pm = baseMessage;
        // Check the payload
        expect(pm.payload.message[0], 'h'.codeUnitAt(0));
        expect(pm.payload.message[1], 'e'.codeUnitAt(0));
        expect(pm.payload.message[2], 'l'.codeUnitAt(0));
        expect(pm.payload.message[3], 'l'.codeUnitAt(0));
        expect(pm.payload.message[4], 'o'.codeUnitAt(0));
        expect(pm.payload.message[5], '!'.codeUnitAt(0));
      });
      test('Deserialisation - payload too short', () {
        final sampleMessage = <int>[
          0x30,
          0x0C,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        var raised = false;
        try {
          final baseMessage = MqttMessage.createFrom(byteBuffer);
          print(baseMessage.toString());
        } on Exception {
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('Serialisation - Qos Level 2 Exactly Once', () {
        final expected = <int>[
          0x34,
          0x0E,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00,
          0x0A,
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final payload = typed.Uint8Buffer(6);
        payload[0] = 'h'.codeUnitAt(0);
        payload[1] = 'e'.codeUnitAt(0);
        payload[2] = 'l'.codeUnitAt(0);
        payload[3] = 'l'.codeUnitAt(0);
        payload[4] = 'o'.codeUnitAt(0);
        payload[5] = '!'.codeUnitAt(0);
        final msg = MqttPublishMessage()
            .withQos(MqttQos.exactlyOnce)
            .withMessageIdentifier(10)
            .toTopic('fred')
            .publishData(payload);
        print('Publish - Qos Level 2 Exactly Once::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
        expect(actual[4], expected[4]); // f
        expect(actual[5], expected[5]); // r
        expect(actual[6], expected[6]); // e
        expect(actual[7], expected[7]); // d
        expect(actual[8], expected[8]); // h
        expect(actual[9], expected[9]); // e
        expect(actual[10], expected[10]); // l
        expect(actual[11], expected[11]); // l
        expect(actual[12], expected[12]); // o
        expect(actual[13], expected[13]); // !
      });
      test('Serialisation - Topic has special characters', () {
        final expected = <int>[
          0x34,
          0x0E,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00,
          0x0A,
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final payload = typed.Uint8Buffer(6);
        payload[0] = 'h'.codeUnitAt(0);
        payload[1] = 'e'.codeUnitAt(0);
        payload[2] = 'l'.codeUnitAt(0);
        payload[3] = 'l'.codeUnitAt(0);
        payload[4] = 'o'.codeUnitAt(0);
        payload[5] = '!'.codeUnitAt(0);
        MqttClientProtocol.version = MqttClientConstants.mqttProtocolVersion;
        final msg = MqttPublishMessage()
            .withQos(MqttQos.exactlyOnce)
            .withMessageIdentifier(10)
            .toTopic(
                '/hfp/v1/journey/ongoing/bus/0012/01314/2550/2/Itäkeskus(M)/19:16/1454121/3/60;25/20/14/83')
            .publishData(payload);
        print('Publish - Qos Level 2 Exactly Once::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, 102);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], 100); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], 89); // second topic length byte
        expect(actual[4], 47);
        expect(actual[5], 104);
        expect(actual[6], 102);
        expect(actual[7], 112);
      });
      test('Serialisation - Qos Level 0 No MID', () {
        final expected = <int>[
          0x30,
          0x0C,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          // message payload is here
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final payload = typed.Uint8Buffer(6);
        payload[0] = 'h'.codeUnitAt(0);
        payload[1] = 'e'.codeUnitAt(0);
        payload[2] = 'l'.codeUnitAt(0);
        payload[3] = 'l'.codeUnitAt(0);
        payload[4] = 'o'.codeUnitAt(0);
        payload[5] = '!'.codeUnitAt(0);
        final msg = MqttPublishMessage().toTopic('fred').publishData(payload);
        print('Publish - Qos Level 0 No MID::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
        expect(actual[4], expected[4]); // f
        expect(actual[5], expected[5]); // r
        expect(actual[6], expected[6]); // e
        expect(actual[7], expected[7]); // d
        expect(actual[8], expected[8]); // h
        expect(actual[9], expected[9]); // e
        expect(actual[10], expected[10]); // l
        expect(actual[11], expected[11]); // l
        expect(actual[12], expected[12]); // o
        expect(actual[13], expected[13]); // !
      });
      test('Serialisation - With non-default Qos', () {
        final msg = MqttPublishMessage()
            .toTopic('mark')
            .withQos(MqttQos.atLeastOnce)
            .withMessageIdentifier(4)
            .publishData(typed.Uint8Buffer(9));
        final msgBytes = MessageSerializationHelper.getMessageBytes(msg);
        expect(msgBytes.length, 19);
      });
      test('Clear publish data', () {
        final data = typed.Uint8Buffer(2);
        data[0] = 0;
        data[1] = 1;
        final msg = MqttPublishMessage().publishData(data);
        expect(msg.payload.message.length, 2);
        msg.clearPublishData();
        expect(msg.payload.message.length, 0);
      });
    });

    group('Publish Ack', () {
      test('Deserialisation - Valid payload', () {
        // Tests basic message deserialization from a raw byte array.
        // Message Specs________________
        // <30><0C><00><04>fredhello!
        final sampleMessage = <int>[
          0x40,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish Ack - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish ack message.
        expect(baseMessage, const TypeMatcher<MqttPublishAckMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.messageType, MqttMessageType.publishAck);
        expect(baseMessage.header.messageSize, 2);
        final MqttPublishAckMessage bm = baseMessage;
        expect(bm.variableHeader.messageIdentifier, 4);
      });
      test('Serialisation - Valid payload', () {
        // Publish ack msg with message identifier 4
        final expected = typed.Uint8Buffer(4);
        expected[0] = 0x40;
        expected[1] = 0x02;
        expected[2] = 0x0;
        expected[3] = 0x4;
        final msg = MqttPublishAckMessage().withMessageIdentifier(4);
        print('Publish Ack - Valid payload::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
      });
    });

    group('Publish Complete', () {
      test('Deserialisation - Valid payload', () {
        // Message Specs________________
        // <40><02><00><04> (Pub complete for Message ID 4)
        final sampleMessage = <int>[
          0x70,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish Complete - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish complete message.
        expect(baseMessage, const TypeMatcher<MqttPublishCompleteMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.messageType, MqttMessageType.publishComplete);
        expect(baseMessage.header.messageSize, 2);
        final MqttPublishCompleteMessage bm = baseMessage;
        expect(bm.variableHeader.messageIdentifier, 4);
      });
      test('Serialisation - Valid payload', () {
        // Publish complete msg with message identifier 4
        final expected = typed.Uint8Buffer(4);
        expected[0] = 0x70;
        expected[1] = 0x02;
        expected[2] = 0x0;
        expected[3] = 0x4;
        final msg = MqttPublishCompleteMessage().withMessageIdentifier(4);
        print('Publish Complete - Valid payload::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
      });
    });

    group('Publish Received', () {
      test('Deserialisation - Valid payload', () {
        // Message Specs________________
        // <40><02><00><04> (Pub Received for Message ID 4)
        final sampleMessage = <int>[
          0x50,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish Received - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish received message.
        expect(baseMessage, const TypeMatcher<MqttPublishReceivedMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.messageType, MqttMessageType.publishReceived);
        expect(baseMessage.header.messageSize, 2);
        final MqttPublishReceivedMessage bm = baseMessage;
        expect(bm.variableHeader.messageIdentifier, 4);
      });
      test('Serialisation - Valid payload', () {
        // Publish complete msg with message identifier 4
        final expected = typed.Uint8Buffer(4);
        expected[0] = 0x50;
        expected[1] = 0x02;
        expected[2] = 0x0;
        expected[3] = 0x4;
        final msg = MqttPublishReceivedMessage().withMessageIdentifier(4);
        print('Publish Received - Valid payload::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
      });
    });

    group('Publish Release', () {
      test('Deserialisation - Valid payload', () {
        // Message Specs________________
        // <40><02><00><04> (Pub Release for Message ID 4)
        final sampleMessage = <int>[
          0x60,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Publish Release - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish release message.
        expect(baseMessage, const TypeMatcher<MqttPublishReleaseMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.messageType, MqttMessageType.publishRelease);
        expect(baseMessage.header.messageSize, 2);
        final MqttPublishReleaseMessage bm = baseMessage;
        expect(bm.variableHeader.messageIdentifier, 4);
      });
      test('Serialisation - Valid payload', () {
        // Publish complete msg with message identifier 4
        final expected = typed.Uint8Buffer(4);
        expected[0] = 0x62;
        expected[1] = 0x02;
        expected[2] = 0x0;
        expected[3] = 0x4;
        final msg = MqttPublishReleaseMessage().withMessageIdentifier(4);
        print('Publish Release - Valid payload::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // first topic length byte
        expect(actual[3], expected[3]); // second topic length byte
      });
    });

    group('Subscribe', () {
      test('Deserialisation - Single topic', () {
        // Message Specs________________
        // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x09,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Subscribe - Single topic::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 1);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.atMostOnce);
      });
      test('Deserialisation - Multi topic', () {
        // Message Specs________________
        // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x10,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00,
          0x00,
          0x04,
          'm'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'k'.codeUnitAt(0),
          0x00
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Subscribe - Multi topic::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 2);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.atMostOnce);
        expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
        expect(bm.payload.subscriptions['mark'], MqttQos.atMostOnce);
      });
      test('Deserialisation - Single topic at least once Qos', () {
        // Message Specs________________
        // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x09,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x01
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe - Single topic at least once Qos::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 1);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.atLeastOnce);
      });
      test('Deserialisation - Multi topic at least once Qos', () {
        // Message Specs________________
        // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x10,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x01,
          0x00,
          0x04,
          'm'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'k'.codeUnitAt(0),
          0x01
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe - Multi topic at least once Qos::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 2);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.atLeastOnce);
        expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
        expect(bm.payload.subscriptions['mark'], MqttQos.atLeastOnce);
      });
      test('Deserialisation - Single topic exactly once Qos', () {
        // Message Specs________________
        // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x09,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x02
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe - Single topic exactly once Qos::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 1);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.exactlyOnce);
      });
      test('Deserialisation - Multi topic exactly once Qos', () {
        // Message Specs________________
        // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
        final sampleMessage = <int>[
          0x82,
          0x10,
          0x00,
          0x02,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x02,
          0x00,
          0x04,
          'm'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'k'.codeUnitAt(0),
          0x02
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe - Multi topic exactly once Qos::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 2);
        expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
        expect(bm.payload.subscriptions['fred'], MqttQos.exactlyOnce);
        expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
        expect(bm.payload.subscriptions['mark'], MqttQos.exactlyOnce);
      });
      test('Serialisation - Single topic', () {
        final expected = typed.Uint8Buffer(11);
        expected[0] = 0x8A;
        expected[1] = 0x09;
        expected[2] = 0x00;
        expected[3] = 0x02;
        expected[4] = 0x00;
        expected[5] = 0x04;
        expected[6] = 'f'.codeUnitAt(0);
        expected[7] = 'r'.codeUnitAt(0);
        expected[8] = 'e'.codeUnitAt(0);
        expected[9] = 'd'.codeUnitAt(0);
        expected[10] = 0x01;
        final msg = MqttSubscribeMessage()
            .toTopic('fred')
            .atQos(MqttQos.atLeastOnce)
            .withMessageIdentifier(2)
            .expectAcknowledgement()
            .isDuplicate();
        print('Subscribe - Single topic::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
        expect(actual[3], expected[3]); // MsgID Byte 2
        expect(actual[4], expected[4]); // Topic Length B1
        expect(actual[5], expected[5]); // Topic Length B2
        expect(actual[6], expected[6]); // f
        expect(actual[7], expected[7]); // r
        expect(actual[8], expected[8]); // e
        expect(actual[9], expected[9]); // d
      });
      test('Serialisation - multi topic', () {
        final expected = typed.Uint8Buffer(18);
        expected[0] = 0x82;
        expected[1] = 0x10;
        expected[2] = 0x00;
        expected[3] = 0x03;
        expected[4] = 0x00;
        expected[5] = 0x04;
        expected[6] = 'f'.codeUnitAt(0);
        expected[7] = 'r'.codeUnitAt(0);
        expected[8] = 'e'.codeUnitAt(0);
        expected[9] = 'd'.codeUnitAt(0);
        expected[10] = 0x01;
        expected[11] = 0x00;
        expected[12] = 0x04;
        expected[13] = 'm'.codeUnitAt(0);
        expected[14] = 'a'.codeUnitAt(0);
        expected[15] = 'r'.codeUnitAt(0);
        expected[16] = 'k'.codeUnitAt(0);
        expected[17] = 0x02;
        final msg = MqttSubscribeMessage()
            .toTopic('fred')
            .atQos(MqttQos.atLeastOnce)
            .toTopic('mark')
            .atQos(MqttQos.exactlyOnce)
            .withMessageIdentifier(3)
            .expectAcknowledgement();
        print('Subscribe - multi topic::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
        expect(actual[3], expected[3]); // MsgID Byte 2
        expect(actual[4], expected[4]); // Topic Length B1
        expect(actual[5], expected[5]); // Topic Length B2
        expect(actual[6], expected[6]); // f
        expect(actual[7], expected[7]); // r
        expect(actual[8], expected[8]); // e
        expect(actual[9], expected[9]); // d
        expect(actual[10], expected[10]); // Qos (LeastOnce)
        expect(actual[11], expected[11]); // Topic Length B1
        expect(actual[12], expected[12]); // Topic Length B2
        expect(actual[13], expected[13]); // m
        expect(actual[14], expected[14]); // a
        expect(actual[15], expected[15]); // r
        expect(actual[16], expected[16]); // k
        expect(actual[17], expected[17]); // Qos (ExactlyOnce)
      });
      test('Add subscription over existing subscription', () {
        final msg = MqttSubscribeMessage();
        msg.payload.addSubscription('A/Topic', MqttQos.atMostOnce);
        msg.payload.addSubscription('A/Topic', MqttQos.atLeastOnce);
        expect(msg.payload.subscriptions['A/Topic'], MqttQos.atLeastOnce);
      });
      test('Clear subscription', () {
        final msg = MqttSubscribeMessage();
        msg.payload.addSubscription('A/Topic', MqttQos.atMostOnce);
        msg.payload.clearSubscriptions();
        expect(msg.payload.subscriptions.length, 0);
      });
    });

    group('Subscribe Ack', () {
      test('Deserialisation - Single Qos at most once', () {
        // Message Specs________________
        // <90><03><00><02><00>
        final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x00];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe Ack - Single Qos at most once::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 1);
        expect(bm.payload.qosGrants[0], MqttQos.atMostOnce);
      });
      test('Deserialisation - Single Qos at least once', () {
        // Message Specs________________
        // <90><03><00><02><01>
        final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x01];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe Ack - Single Qos at least once::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 1);
        expect(bm.payload.qosGrants[0], MqttQos.atLeastOnce);
      });
      test('Deserialisation - Single Qos exactly once', () {
        // Message Specs________________
        // <90><03><00><02><02>
        final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x02];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(
            'Subscribe Ack - Single Qos exactly once::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 1);
        expect(bm.payload.qosGrants[0], MqttQos.exactlyOnce);
      });
      test('Deserialisation - Single Qos failure', () {
        // Message Specs________________
        // <90><03><00><02><0x80>
        final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x80];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Subscribe Ack - Single Qos failure::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 1);
        expect(bm.payload.qosGrants[0], MqttQos.failure);
      });
      test('Deserialisation - Single Qos reserved1', () {
        // Message Specs________________
        // <90><03><00><02><0x55>
        final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x55];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Subscribe Ack - Single Qos failure::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 1);
        expect(bm.payload.qosGrants[0], MqttQos.reserved1);
      });
      test('Deserialisation - Multi Qos', () {
        // Message Specs________________
        // <90><03><00><02><00> <01><02>
        final sampleMessage = <int>[0x90, 0x05, 0x00, 0x02, 0x0, 0x01, 0x02];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Subscribe Ack - multi Qos::${baseMessage.toString()}');
        // Check that the message was correctly identified as a subscribe ack message.
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        final MqttSubscribeAckMessage bm = baseMessage;
        expect(bm.payload.qosGrants.length, 3);
        expect(bm.payload.qosGrants[0], MqttQos.atMostOnce);
        expect(bm.payload.qosGrants[1], MqttQos.atLeastOnce);
        expect(bm.payload.qosGrants[2], MqttQos.exactlyOnce);
      });
      test('Serialisation - Single Qos at most once', () {
        final expected = typed.Uint8Buffer(5);
        expected[0] = 0x90;
        expected[1] = 0x03;
        expected[2] = 0x00;
        expected[3] = 0x02;
        expected[4] = 0x00;
        final msg = MqttSubscribeAckMessage()
            .withMessageIdentifier(2)
            .addQosGrant(MqttQos.atMostOnce);
        print('Subscribe Ack - Single Qos at most once::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // message id b1
        expect(actual[3], expected[3]); // message id b2
        expect(actual[4], expected[4]); // QOS
      });
      test('Serialisation - Single Qos at least once', () {
        final expected = typed.Uint8Buffer(5);
        expected[0] = 0x90;
        expected[1] = 0x03;
        expected[2] = 0x00;
        expected[3] = 0x02;
        expected[4] = 0x01;
        final msg = MqttSubscribeAckMessage()
            .withMessageIdentifier(2)
            .addQosGrant(MqttQos.atLeastOnce);
        print('Subscribe Ack - Single Qos at least once::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // message id b1
        expect(actual[3], expected[3]); // message id b2
        expect(actual[4], expected[4]); // QOS
      });
      test('Serialisation - Single Qos exactly once', () {
        final expected = typed.Uint8Buffer(5);
        expected[0] = 0x90;
        expected[1] = 0x03;
        expected[2] = 0x00;
        expected[3] = 0x02;
        expected[4] = 0x02;
        final msg = MqttSubscribeAckMessage()
            .withMessageIdentifier(2)
            .addQosGrant(MqttQos.exactlyOnce);
        print('Subscribe Ack - Single Qos exactly once::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // message id b1
        expect(actual[3], expected[3]); // message id b2
        expect(actual[4], expected[4]); // QOS
      });
      test('Serialisation - Multi QOS', () {
        final expected = typed.Uint8Buffer(7);
        expected[0] = 0x90;
        expected[1] = 0x05;
        expected[2] = 0x00;
        expected[3] = 0x02;
        expected[4] = 0x00;
        expected[5] = 0x01;
        expected[6] = 0x02;
        final msg = MqttSubscribeAckMessage()
            .withMessageIdentifier(2)
            .addQosGrant(MqttQos.atMostOnce)
            .addQosGrant(MqttQos.atLeastOnce)
            .addQosGrant(MqttQos.exactlyOnce);
        print('Subscribe Ack - Multi QOS::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // message id b1
        expect(actual[3], expected[3]); // message id b2
        expect(actual[4], expected[4]); // QOS 1 (Most)
        expect(actual[5], expected[5]); // QOS 2 (Least)
        expect(actual[6], expected[6]); // QOS 3 (Exactly)
      });
      test('Serialisation - Clear grants', () {
        final msg = MqttSubscribeAckMessage()
            .withMessageIdentifier(2)
            .addQosGrant(MqttQos.atMostOnce)
            .addQosGrant(MqttQos.atLeastOnce)
            .addQosGrant(MqttQos.exactlyOnce);
        expect(msg.payload.qosGrants.length, 3);
        msg.payload.clearGrants();
        expect(msg.payload.qosGrants.length, 0);
      });
    });

    group('Unsubscribe', () {
      test('Deserialisation - Single topic', () {
        // Message Specs________________
        // <A2><08><00><03><00><04>fred (Unsubscribe to topic fred)
        final sampleMessage = <int>[
          0xA2,
          0x08,
          0x00,
          0x03,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Unsubscribe - Single topic::${baseMessage.toString()}');
        // Check that the message was correctly identified as an unsubscribe message.
        expect(baseMessage, const TypeMatcher<MqttUnsubscribeMessage>());
        final MqttUnsubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 1);
        expect(bm.payload.subscriptions.contains('fred'), isTrue);
      });
      test('Deserialisation - Multi topic', () {
        // Message Specs________________
        // <A2><0E><00><03><00><04>fred<00><04>mark (Unsubscribe to topic fred, mark)
        final sampleMessage = <int>[
          0xA2,
          0x0E,
          0x00,
          0x03,
          0x00,
          0x04,
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00,
          0x04,
          'm'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'k'.codeUnitAt(0),
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Unsubscribe - Multi topic::${baseMessage.toString()}');
        // Check that the message was correctly identified as an unsubscribe message.
        expect(baseMessage, const TypeMatcher<MqttUnsubscribeMessage>());
        final MqttUnsubscribeMessage bm = baseMessage;
        expect(bm.payload.subscriptions.length, 2);
        expect(bm.payload.subscriptions.contains('fred'), isTrue);
        expect(bm.payload.subscriptions.contains('mark'), isTrue);
      });
      test('Serialisation - Single topic', () {
        final expected = typed.Uint8Buffer(10);
        expected[0] = 0xAA;
        expected[1] = 0x08;
        expected[2] = 0x00;
        expected[3] = 0x03;
        expected[4] = 0x00;
        expected[5] = 0x04;
        expected[6] = 'f'.codeUnitAt(0);
        expected[7] = 'r'.codeUnitAt(0);
        expected[8] = 'e'.codeUnitAt(0);
        expected[9] = 'd'.codeUnitAt(0);
        final msg = MqttUnsubscribeMessage()
            .fromTopic('fred')
            .withMessageIdentifier(3)
            .expectAcknowledgement()
            .isDuplicate();
        print('Unsubscribe - Single topic::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
        expect(actual[3], expected[3]); // MsgID Byte 2
        expect(actual[4], expected[4]); // Topic Length B1
        expect(actual[5], expected[5]); // Topic Length B2
        expect(actual[6], expected[6]); // f
        expect(actual[7], expected[7]); // r
        expect(actual[8], expected[8]); // e
        expect(actual[9], expected[9]); // d
      });
      test('Serialisation V311 - Single topic', () {
        MqttClientProtocol.version = MqttClientConstants.mqttProtocolVersion;
        final expected = typed.Uint8Buffer(10);
        expected[0] = 0xA2; // With V3.1.1 the header first byte changes to 162
        expected[1] = 0x08;
        expected[2] = 0x00;
        expected[3] = 0x03;
        expected[4] = 0x00;
        expected[5] = 0x04;
        expected[6] = 'f'.codeUnitAt(0);
        expected[7] = 'r'.codeUnitAt(0);
        expected[8] = 'e'.codeUnitAt(0);
        expected[9] = 'd'.codeUnitAt(0);
        final msg = MqttUnsubscribeMessage()
            .fromTopic('fred')
            .withMessageIdentifier(3)
            .expectAcknowledgement()
            .isDuplicate();
        print('Unsubscribe - Single topic::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
        expect(actual[3], expected[3]); // MsgID Byte 2
        expect(actual[4], expected[4]); // Topic Length B1
        expect(actual[5], expected[5]); // Topic Length B2
        expect(actual[6], expected[6]); // f
        expect(actual[7], expected[7]); // r
        expect(actual[8], expected[8]); // e
        expect(actual[9], expected[9]); // d
      });
      test('Serialisation - multi topic', () {
        final expected = typed.Uint8Buffer(16);
        expected[0] = 0xA2;
        expected[1] = 0x0E;
        expected[2] = 0x00;
        expected[3] = 0x03;
        expected[4] = 0x00;
        expected[5] = 0x04;
        expected[6] = 'f'.codeUnitAt(0);
        expected[7] = 'r'.codeUnitAt(0);
        expected[8] = 'e'.codeUnitAt(0);
        expected[9] = 'd'.codeUnitAt(0);
        expected[10] = 0x00;
        expected[11] = 0x04;
        expected[12] = 'm'.codeUnitAt(0);
        expected[13] = 'a'.codeUnitAt(0);
        expected[14] = 'r'.codeUnitAt(0);
        expected[15] = 'k'.codeUnitAt(0);
        final msg = MqttUnsubscribeMessage()
            .fromTopic('fred')
            .fromTopic('mark')
            .withMessageIdentifier(3)
            .expectAcknowledgement();
        print('Unubscribe - multi topic::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
        expect(actual[3], expected[3]); // MsgID Byte 2
        expect(actual[4], expected[4]); // Topic Length B1
        expect(actual[5], expected[5]); // Topic Length B2
        expect(actual[6], expected[6]); // f
        expect(actual[7], expected[7]); // r
        expect(actual[8], expected[8]); // e
        expect(actual[9], expected[9]); // d
        expect(actual[10], expected[10]); // Topic Length B1
        expect(actual[11], expected[11]); // Topic Length B2
        expect(actual[12], expected[12]); // m
        expect(actual[13], expected[13]); // a
        expect(actual[14], expected[14]); // r
        expect(actual[15], expected[15]); // k
      });
      test('Clear subscription', () {
        final msg = MqttUnsubscribeMessage();
        msg.payload.addSubscription('A/Topic');
        msg.payload.clearSubscriptions();
        expect(msg.payload.subscriptions.length, 0);
      });
    });

    group('Unsubscribe Ack', () {
      test('Deserialisation - Valid payload', () {
        // Message Specs________________
        // <B0><02><00><04> (Subscribe ack for message id 4)
        final sampleMessage = <int>[
          0xB0,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print('Unsubscribe Ack - Valid payload::${baseMessage.toString()}');
        // Check that the message was correctly identified as a publish release message.
        expect(baseMessage, const TypeMatcher<MqttUnsubscribeAckMessage>());
        // Validate the message deserialization
        expect(baseMessage.header.messageType, MqttMessageType.unsubscribeAck);
        expect(baseMessage.header.messageSize, 2);
        final MqttUnsubscribeAckMessage bm = baseMessage;
        expect(bm.variableHeader.messageIdentifier, 4);
      });
      test('Serialisation - Valid payload', () {
        // Publish complete msg with message identifier 4
        final expected = typed.Uint8Buffer(4);
        expected[0] = 0xB0;
        expected[1] = 0x02;
        expected[2] = 0x0;
        expected[3] = 0x4;
        final msg = MqttUnsubscribeAckMessage().withMessageIdentifier(4);
        print('Unsubscribe Ack - Valid payload::${msg.toString()}');
        final actual = MessageSerializationHelper.getMessageBytes(msg);
        expect(actual.length, expected.length);
        expect(actual[0], expected[0]); // msg type of header + other bits
        expect(actual[1], expected[1]); // remaining length
        expect(
            actual[2], expected[2]); // connect ack - compression? always empty
        expect(actual[3], expected[3]); // return code.
      });
    });

    group('Unimplemented', () {
      test('Deserialisation - Invalid payload', () {
        final sampleMessage = <int>[
          0xFF,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        var raised = false;
        try {
          final baseMessage = MqttMessage.createFrom(byteBuffer);
          print(baseMessage.toString());
        } on Exception {
          raised = true;
        }
        expect(raised, isTrue);
      });
    });
  });
}
