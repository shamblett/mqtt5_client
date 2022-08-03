/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

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
  group('Message Identifier', () {
    test('Numbering starts at 1', () {
      final dispenser = MqttMessageIdentifierDispenser();
      expect(dispenser.nextMessageIdentifier, 1);
    });
    test('Numbering increments by 1', () {
      final dispenser = MqttMessageIdentifierDispenser();
      final first = dispenser.nextMessageIdentifier;
      final second = dispenser.nextMessageIdentifier;
      expect(second, first + 1);
    });
    test('Numbering overflows back to 1', () {
      final dispenser = MqttMessageIdentifierDispenser();
      dispenser.reset();
      for (var i = 0;
          i == MqttMessageIdentifierDispenser.maxMessageIdentifier;
          i++) {
        dispenser.nextMessageIdentifier;
      }
      // One more call should overflow us and reset us back to 1.
      expect(dispenser.nextMessageIdentifier, 1);
    });
  });

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
        MqttHeader.fromByteBuffer(buffer);
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
        MqttHeader.fromByteBuffer(buffer);
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
      expect(property.getWriteLength(), 2);
      property.value = 268435455;
      expect(property.getWriteLength(), 5);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      property.writeTo(stream);
      stream.reset();
      expect(stream.readByte(),
          mqttPropertyIdentifier.asInt(MqttPropertyIdentifier.contentType));
      expect(stream.readByte(), 0xff);
      expect(stream.readByte(), 0xff);
      expect(stream.readByte(), 0xff);
      expect(stream.readByte(), 0x7f);
      final property1 =
          MqttVariableByteIntegerProperty(MqttPropertyIdentifier.notSet);
      stream.reset();
      property1.readFrom(stream);
      expect(property1.identifier, MqttPropertyIdentifier.contentType);
      expect(property1.value, 268435455);
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
        expect(property, isA<MqttUserProperty>());
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
        final userProperty1 = MqttUserProperty();
        userProperty1.pairName = 'First';
        userProperty1.pairValue = 'First Value';
        final userProperty2 = MqttUserProperty();
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
        final userProperty1 = MqttUserProperty();
        userProperty1.pairName = 'First';
        userProperty1.pairValue = 'First Value';
        final userProperty2 = MqttUserProperty();
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
        final userProperty1 = MqttUserProperty();
        userProperty1.pairName = 'a';
        userProperty1.pairValue = 'b';
        final userProperty2 = MqttUserProperty();
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
        expect(stream.buffer!.toList(),
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
        expect(propList[2], isA<MqttUserProperty>());
        expect(propList[3], isA<MqttUserProperty>());
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
    group('Connect Message', () {
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
        var property1 = MqttUserProperty();
        property1.pairName = 'Prop1';
        property1.pairValue = 'Prop1Value';
        var property2 = MqttUserProperty();
        property2.pairName = 'Prop2';
        property2.pairValue = 'Prop2Value';
        variableHeader.userProperty = [property1, property2];
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
        expect(variableHeader.userProperty[0], property1);
        expect(variableHeader.userProperty[1], property2);
      });
    });
    group('Connect Ack Message', () {
      test('Variable Header Connect Ack - Defaults', () {
        final message = MqttConnectAckVariableHeader();
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Session present
        buffer.add(0xff); // Reason code not set
        buffer.add(0); // No properties
        final stream = MqttByteBuffer(buffer);
        final message1 = MqttConnectAckVariableHeader.fromByteBuffer(stream);
        expect(message.connectAckFlags.sessionPresent, isFalse);
        expect(message1.connectAckFlags.sessionPresent, isFalse);
        expect(message.reasonCode, MqttConnectReasonCode.notSet);
        expect(message1.reasonCode, MqttConnectReasonCode.notSet);
        expect(message.sessionExpiryInterval, 0);
        expect(message1.sessionExpiryInterval, 0);
        expect(message.receiveMaximum, 65535);
        expect(message1.receiveMaximum, 65535);
        expect(message.maximumQos, 2);
        expect(message1.maximumQos, 2);
        expect(message.retainAvailable, isFalse);
        expect(message1.retainAvailable, isFalse);
        expect(message.maximumPacketSize, 0);
        expect(message1.maximumPacketSize, 0);
        expect(message.assignedClientIdentifier, isNull);
        expect(message1.assignedClientIdentifier, isNull);
        expect(message.topicAliasMaximum, 0);
        expect(message1.topicAliasMaximum, 0);
        expect(message.reasonString, isNull);
        expect(message1.reasonString, isNull);
        expect(message.userProperty, isNull);
        expect(message1.userProperty, isNull);
        expect(message.wildcardSubscriptionsAvailable, isTrue);
        expect(message1.wildcardSubscriptionsAvailable, isTrue);
        expect(message.subscriptionIdentifiersAvailable, isTrue);
        expect(message1.subscriptionIdentifiersAvailable, isTrue);
        expect(message.sharedSubscriptionAvailable, isTrue);
        expect(message1.sharedSubscriptionAvailable, isTrue);
        expect(message.serverKeepAlive, 0);
        expect(message1.serverKeepAlive, 0);
        expect(message.responseInformation, isNull);
        expect(message1.responseInformation, isNull);
        expect(message.serverReference, isNull);
        expect(message1.serverReference, isNull);
        expect(message.authenticationMethod, isNull);
        expect(message1.authenticationMethod, isNull);
        expect(message.authenticationData, isNull);
        expect(message1.authenticationData, isNull);
        expect(message.getWriteLength(), 0);
        expect(message1.getWriteLength(), 0);
      });
      test('Variable Header Connect Ack - All', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(1); // Session present
        buffer.add(0); // Reason code success
        final properties = MqttPropertyContainer();
        var property4Byte1 = MqttFourByteIntegerProperty(
            MqttPropertyIdentifier.sessionExpiryInterval);
        property4Byte1.value = 30;
        properties.add(property4Byte1);
        var property2Byte1 =
            MqttTwoByteIntegerProperty(MqttPropertyIdentifier.receiveMaximum);
        property2Byte1.value = 1024;
        properties.add(property2Byte1);
        var propertyByte1 = MqttByteProperty(MqttPropertyIdentifier.maximumQos);
        propertyByte1.value = 1;
        properties.add(propertyByte1);
        var propertyByte2 =
            MqttByteProperty(MqttPropertyIdentifier.retainAvailable);
        propertyByte2.value = 1;
        properties.add(propertyByte2);
        var property4Byte2 = MqttFourByteIntegerProperty(
            MqttPropertyIdentifier.maximumPacketSize);
        property4Byte2.value = 2048;
        properties.add(property4Byte2);
        var propertyString1 = MqttUtf8StringProperty(
            MqttPropertyIdentifier.assignedClientIdentifier);
        propertyString1.value = 'Assigned CLID';
        properties.add(propertyString1);
        var property2Byte2 = MqttTwoByteIntegerProperty(
            MqttPropertyIdentifier.topicAliasMaximum);
        property2Byte2.value = 10;
        properties.add(property2Byte2);
        var propertyString2 =
            MqttUtf8StringProperty(MqttPropertyIdentifier.reasonString);
        propertyString2.value = 'Reason String';
        properties.add(propertyString2);
        var propertyByte3 = MqttByteProperty(
            MqttPropertyIdentifier.wildcardSubscriptionAvailable);
        propertyByte3.value = 0;
        properties.add(propertyByte3);
        var propertyByte4 = MqttByteProperty(
            MqttPropertyIdentifier.sharedSubscriptionAvailable);
        propertyByte4.value = 0;
        properties.add(propertyByte4);
        var propertyByte5 = MqttByteProperty(
            MqttPropertyIdentifier.subscriptionIdentifierAvailable);
        propertyByte5.value = 0;
        properties.add(propertyByte5);
        var property2Byte3 =
            MqttTwoByteIntegerProperty(MqttPropertyIdentifier.serverKeepAlive);
        property2Byte3.value = 40;
        properties.add(property2Byte3);
        var propertyString3 =
            MqttUtf8StringProperty(MqttPropertyIdentifier.responseInformation);
        propertyString3.value = 'Response Information';
        properties.add(propertyString3);
        var propertyString4 =
            MqttUtf8StringProperty(MqttPropertyIdentifier.serverReference);
        propertyString4.value = 'Server Reference';
        properties.add(propertyString4);
        var propertyString5 =
            MqttUtf8StringProperty(MqttPropertyIdentifier.authenticationMethod);
        propertyString5.value = 'Authentication Method';
        properties.add(propertyString5);
        var propertyBinary =
            MqttBinaryDataProperty(MqttPropertyIdentifier.authenticationData);
        var authData = typed.Uint8Buffer()..addAll([1, 2, 3, 4]);
        propertyBinary.addBytes(authData);
        properties.add(propertyBinary);
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        var user2 = MqttUserProperty();
        user2.pairName = 'User 2 name';
        user2.pairValue = 'User 2 value';
        properties.add(user2);
        final propBuffer = typed.Uint8Buffer();
        final propStream = MqttByteBuffer(propBuffer);
        properties.writeTo(propStream);
        buffer.addAll(propStream.buffer!);
        final stream = MqttByteBuffer(buffer);
        final message = MqttConnectAckVariableHeader.fromByteBuffer(stream);
        expect(message.connectAckFlags.sessionPresent, isTrue);
        expect(message.reasonCode, MqttConnectReasonCode.success);
        expect(message.sessionExpiryInterval, 30);
        expect(message.receiveMaximum, 1024);
        expect(message.maximumQos, 1);
        expect(message.retainAvailable, isTrue);
        expect(message.maximumPacketSize, 2048);
        expect(message.userProperty, isNotNull);
        expect(message.userProperty![0].pairName, 'User 1 name');
        expect(message.userProperty![0].pairValue, 'User 1 value');
        expect(message.userProperty![1].pairName, 'User 2 name');
        expect(message.userProperty![1].pairValue, 'User 2 value');
        expect(message.wildcardSubscriptionsAvailable, isFalse);
        expect(message.subscriptionIdentifiersAvailable, isFalse);
        expect(message.sharedSubscriptionAvailable, isFalse);
        expect(message.serverKeepAlive, 40);
        expect(message.responseInformation, 'Response Information');
        expect(message.serverReference, 'Server Reference');
        expect(message.authenticationMethod, 'Authentication Method');
        expect(message.authenticationData!.toList(), [1, 2, 3, 4]);
        expect(message.getWriteLength(), 0);
      });
    });
    group('Publish Message', () {
      test('Variable Header Publish - Defaults', () {
        final header = MqttHeader();
        header.messageType = MqttMessageType.publish;
        final message = MqttPublishVariableHeader(header);
        expect(message.topicName, '');
        expect(message.messageIdentifier, 0);
        expect(message.payloadFormatIndicator, isFalse);
        expect(message.messageExpiryInterval, 65535);
        expect(message.topicAlias, 255);
        expect(message.responseTopic, '');
        expect(message.correlationData, isNull);
        expect(message.userProperty, isEmpty);
        expect(message.subscriptionIdentifier, isEmpty);
        expect(message.contentType, '');
        expect(message.length, 0);
        expect(message.getWriteLength(), 3);
        message.header!.qos = MqttQos.atLeastOnce;
        expect(message.length, 0);
        expect(message.getWriteLength(), 5);
        message.header!.qos = MqttQos.exactlyOnce;
        expect(message.getWriteLength(), 5);
      });
      test('Variable Header Publish - Reversible With Qos', () {
        final header = MqttHeader();
        header.qos = MqttQos.atLeastOnce;
        header.messageType = MqttMessageType.publish;
        final message = MqttPublishVariableHeader(header);
        message.topicName = 'TopicName';
        message.messageIdentifier = 1;
        message.payloadFormatIndicator = true;
        message.messageExpiryInterval = 10;
        message.topicAlias = 5;
        message.responseTopic = 'ResponseTopic';
        message.correlationData = typed.Uint8Buffer()..addAll([1, 2, 3, 4, 5]);
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        var user2 = MqttUserProperty();
        user2.pairName = 'User 2 name';
        user2.pairValue = 'User 2 value';
        properties.add(user2);
        message.userProperty = properties;
        message.subscriptionIdentifier = 0xa0;
        message.contentType = 'Content Type';
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(message.getWriteLength(), stream.length);
        header.messageSize = stream.length;
        stream.reset();
        final message1 =
            MqttPublishVariableHeader.fromByteBuffer(header, stream);
        expect(message1.topicName, 'TopicName');
        expect(message1.messageIdentifier, 1);
        expect(message1.payloadFormatIndicator, isTrue);
        expect(message1.messageExpiryInterval, 10);
        expect(message1.topicAlias, 5);
        expect(message1.responseTopic, 'ResponseTopic');
        expect(message1.correlationData, [1, 2, 3, 4, 5]);
        expect(message1.userProperty, isNotEmpty);
        expect(message1.userProperty[0].pairName, 'User 1 name');
        expect(message1.userProperty[0].pairValue, 'User 1 value');
        expect(message1.userProperty[1].pairName, 'User 2 name');
        expect(message1.userProperty[1].pairValue, 'User 2 value');
        expect(message1.subscriptionIdentifier, isNotEmpty);
        expect(message1.subscriptionIdentifier[0], 0xa0);
        expect(message1.contentType, 'Content Type');
      });
      test('Variable Header Publish - Reversible No Qos', () {
        final header = MqttHeader();
        header.messageType = MqttMessageType.publish;
        final message = MqttPublishVariableHeader(header);
        message.topicName = 'TopicName';
        message.payloadFormatIndicator = true;
        message.messageExpiryInterval = 10;
        message.topicAlias = 5;
        message.responseTopic = 'ResponseTopic';
        message.correlationData = typed.Uint8Buffer()..addAll([1, 2, 3, 4, 5]);
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        var user2 = MqttUserProperty();
        user2.pairName = 'User 2 name';
        user2.pairValue = 'User 2 value';
        properties.add(user2);
        message.userProperty = properties;
        message.subscriptionIdentifier = 0xa0;
        message.contentType = 'Content Type';
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(message.getWriteLength(), stream.length);
        header.messageSize = stream.length;
        stream.reset();
        final message1 =
            MqttPublishVariableHeader.fromByteBuffer(header, stream);
        expect(message1.topicName, 'TopicName');
        expect(message1.messageIdentifier, 0);
        expect(message1.payloadFormatIndicator, isTrue);
        expect(message1.messageExpiryInterval, 10);
        expect(message1.topicAlias, 5);
        expect(message1.responseTopic, 'ResponseTopic');
        expect(message1.correlationData, [1, 2, 3, 4, 5]);
        expect(message1.userProperty, isNotEmpty);
        expect(message1.userProperty[0].pairName, 'User 1 name');
        expect(message1.userProperty[0].pairValue, 'User 1 value');
        expect(message1.userProperty[1].pairName, 'User 2 name');
        expect(message1.userProperty[1].pairValue, 'User 2 value');
        expect(message1.subscriptionIdentifier, isNotEmpty);
        expect(message1.subscriptionIdentifier[0], 0xa0);
        expect(message1.contentType, 'Content Type');
      });
    });
    group('Publish Received Message', () {
      test('Variable Header Publish Received - Defaults', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        mHeader.messageSize = 0x00;
        final header = MqttPublishAckVariableHeader(mHeader);
        expect(header.messageIdentifier, 0);
        expect(header.reasonCode, MqttPublishReasonCode.notSet);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 4);
      });
      test('Variable Header Publish Received - Deserialize - No Reason Code',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        mHeader.messageSize = 0x02;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReceivedVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.success);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Received - Deserialize - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        mHeader.messageSize = 0x03;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReceivedVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Received - Deserialize - All', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        mHeader.messageSize = 0x18;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReceivedVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, 'abcd');
        expect(header.userProperty[0].pairName, 'name');
        expect(header.userProperty[0].pairValue, 'val1');
        expect(header.length, 24);
      });
      test('Variable Header Publish Received - Serialize - No Reason Code', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        final header = MqttPublishReceivedVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.success;
        expect(header.getWriteLength(), 2);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2]);
      });
      test(
          'Variable Header Publish Received - Serialize - Reason Code - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        final header = MqttPublishReceivedVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        expect(header.getWriteLength(), 4);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2, 0x80, 0]);
      });
      test(
          'Variable Header Publish Received - Serialize - Reason Code - With Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishReceived);
        final header = MqttPublishReceivedVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        header.reasonString = 'abcd';
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        expect(header.getWriteLength(), 39);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          0,
          2,
          128,
          35,
          31,
          0,
          4,
          97,
          98,
          99,
          100,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    group('Publish Release Message', () {
      test('Variable Header Publish Release - Defaults', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        mHeader.messageSize = 0x00;
        final header = MqttPublishReleaseVariableHeader(mHeader);
        expect(header.messageIdentifier, 0);
        expect(header.reasonCode, MqttPublishReasonCode.notSet);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 4);
      });
      test('Variable Header Publish Release - Deserialize - No Reason Code',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        mHeader.messageSize = 0x02;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReleaseVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.success);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Release - Deserialize - No Properties', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        mHeader.messageSize = 0x03;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReleaseVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Release - Deserialize - All', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        mHeader.messageSize = 0x18;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishReleaseVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, 'abcd');
        expect(header.userProperty[0].pairName, 'name');
        expect(header.userProperty[0].pairValue, 'val1');
        expect(header.length, 24);
      });
      test('Variable Header Publish Release - Serialize - No Reason Code', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        final header = MqttPublishReleaseVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.success;
        expect(header.getWriteLength(), 2);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2]);
      });
      test(
          'Variable Header Publish Release - Serialize - Reason Code - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        final header = MqttPublishReleaseVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        expect(header.getWriteLength(), 4);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2, 0x80, 0]);
      });
      test(
          'Variable Header Publish Release - Serialize - Reason Code - With Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishRelease);
        final header = MqttPublishReleaseVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        header.reasonString = 'abcd';
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        expect(header.getWriteLength(), 39);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          0,
          2,
          128,
          35,
          31,
          0,
          4,
          97,
          98,
          99,
          100,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    group('Publish Complete Message', () {
      test('Variable Header Publish Complete - Defaults', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        mHeader.messageSize = 0x00;
        final header = MqttPublishCompleteVariableHeader(mHeader);
        expect(header.messageIdentifier, 0);
        expect(header.reasonCode, MqttPublishReasonCode.notSet);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 4);
      });
      test('Variable Header Publish Complete - Deserialize - No Reason Code',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        mHeader.messageSize = 0x02;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishCompleteVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.success);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Complete - Deserialize - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        mHeader.messageSize = 0x03;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishCompleteVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Complete - Deserialize - All', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        mHeader.messageSize = 0x18;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishCompleteVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, 'abcd');
        expect(header.userProperty[0].pairName, 'name');
        expect(header.userProperty[0].pairValue, 'val1');
        expect(header.length, 24);
      });
      test('Variable Header Publish Complete - Serialize - No Reason Code', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        final header = MqttPublishCompleteVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.success;
        expect(header.getWriteLength(), 2);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2]);
      });
      test(
          'Variable Header Publish Complete - Serialize - Reason Code - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        final header = MqttPublishCompleteVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        expect(header.getWriteLength(), 4);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2, 0x80, 0]);
      });
      test(
          'Variable Header Publish Complete - Serialize - Reason Code - With Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishComplete);
        final header = MqttPublishCompleteVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        header.reasonString = 'abcd';
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        expect(header.getWriteLength(), 39);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          0,
          2,
          128,
          35,
          31,
          0,
          4,
          97,
          98,
          99,
          100,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    group('Publish Ack Message', () {
      test('Variable Header Publish Ack - Defaults', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        mHeader.messageSize = 0x00;
        final header = MqttPublishAckVariableHeader(mHeader);
        expect(header.messageIdentifier, 0);
        expect(header.reasonCode, MqttPublishReasonCode.notSet);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 4);
      });
      test('Variable Header Publish Ack - Deserialize - No Reason Code', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        mHeader.messageSize = 0x02;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishAckVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.success);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Ack - Deserialize - No Properties', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        mHeader.messageSize = 0x03;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishAckVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, isNull);
        expect(header.userProperty, isEmpty);
      });
      test('Variable Header Publish Ack - Deserialize - All', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        mHeader.messageSize = 0x18;
        final buffer = typed.Uint8Buffer();
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttPublishAckVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.messageIdentifier, 1);
        expect(header.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(header.reasonString, 'abcd');
        expect(header.userProperty[0].pairName, 'name');
        expect(header.userProperty[0].pairValue, 'val1');
        expect(header.length, 24);
      });
      test('Variable Header Publish Ack - Serialize - No Reason Code', () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        final header = MqttPublishAckVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.success;
        expect(header.getWriteLength(), 2);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2]);
      });
      test(
          'Variable Header Publish Ack - Serialize - Reason Code - No Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        final header = MqttPublishAckVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        expect(header.getWriteLength(), 4);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [0, 2, 0x80, 0]);
      });
      test(
          'Variable Header Publish Ack - Serialize - Reason Code - With Properties',
          () {
        final mHeader = MqttHeader().asType(MqttMessageType.publishAck);
        final header = MqttPublishAckVariableHeader(mHeader);
        header.messageIdentifier = 2;
        header.reasonCode = MqttPublishReasonCode.unspecifiedError;
        header.reasonString = 'abcd';
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        expect(header.getWriteLength(), 39);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          0,
          2,
          128,
          35,
          31,
          0,
          4,
          97,
          98,
          99,
          100,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    group('Subscribe Message', () {
      test('Variable Header Subscribe - Defaults', () {
        final header = MqttSubscribeVariableHeader();
        expect(header.messageIdentifier, 0);
        expect(header.subscriptionIdentifier, 0);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 3);
        expect(header.length, 0);
      });
      test('Variable Header Subscribe - Serialize - All', () {
        final header = MqttSubscribeVariableHeader();
        header.messageIdentifier = 2;
        header.subscriptionIdentifier = 10;
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        expect(header.getWriteLength(), 33);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(header.messageIdentifier, 2);
        expect(header.subscriptionIdentifier, 10);
        expect(header.userProperty, isNotEmpty);
        expect(header.userProperty[0].pairName, 'User 1 name');
        expect(header.userProperty[0].pairValue, 'User 1 value');
      });
    });
    group('Subscribe Ack Message', () {
      test('Variable Header Subscribe Ack - Defaults', () {
        final header = MqttSubscribeAckVariableHeader();
        expect(header.messageIdentifier, 0);
        expect(header.userProperty, isEmpty);
        expect(header.reasonString, isNull);
        expect(header.getWriteLength(), 0);
        expect(header.length, 0);
      });
      test('Variable Header Subscribe Ack - Deserialize - All', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x00); // Message identifier
        buffer.add(0x0a);
        buffer.add(0x14); // Property length
        buffer.add(0x1f); // Reason String
        buffer.add(0x00);
        buffer.add(0x06);
        buffer.add('r'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('s'.codeUnitAt(0));
        buffer.add('o'.codeUnitAt(0));
        buffer.add('n'.codeUnitAt(0));
        buffer.add(0x26); // User property
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('d'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('f'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header = MqttSubscribeAckVariableHeader.fromByteBuffer(stream);
        expect(header.messageIdentifier, 10);
        expect(header.userProperty[0].pairName, 'abc');
        expect(header.userProperty[0].pairValue, 'def');
        expect(header.reasonString, 'reason');
        expect(header.length, 0x17);
      });
    });
    group('Unsubscribe Message', () {
      test('Variable Header Unsubscribe - Defaults', () {
        final header = MqttUnsubscribeVariableHeader();
        expect(header.messageIdentifier, 0);
        expect(header.userProperty, isEmpty);
        expect(header.getWriteLength(), 3);
        expect(header.length, 0);
      });
      test('Variable Header Unsubscribe - User properties', () {
        final header = MqttUnsubscribeVariableHeader();
        header.messageIdentifier = 10;
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        final buffer = typed.Uint8Buffer();
        expect(header.getWriteLength(), 31);
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          0,
          10,
          28,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    group('Unsubscribe Ack Message', () {
      test('Variable Header Unubscribe Ack - Defaults', () {
        final header = MqttUnsubscribeAckVariableHeader();
        expect(header.messageIdentifier, 0);
        expect(header.userProperty, isEmpty);
        expect(header.reasonString, isNull);
        expect(header.getWriteLength(), 0);
        expect(header.length, 0);
      });
      test('Variable Header Unsubscribe Ack - Deserialize - All', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x00); // Message identifier
        buffer.add(0x0a);
        buffer.add(0x14); // Property length
        buffer.add(0x1f); // Reason String
        buffer.add(0x00);
        buffer.add(0x06);
        buffer.add('r'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('s'.codeUnitAt(0));
        buffer.add('o'.codeUnitAt(0));
        buffer.add('n'.codeUnitAt(0));
        buffer.add(0x26); // User property
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('d'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('f'.codeUnitAt(0));
        final stream = MqttByteBuffer(buffer);
        final header = MqttUnsubscribeAckVariableHeader.fromByteBuffer(stream);
        expect(header.messageIdentifier, 10);
        expect(header.userProperty[0].pairName, 'abc');
        expect(header.userProperty[0].pairValue, 'def');
        expect(header.reasonString, 'reason');
        expect(header.length, 0x17);
      });
    });
    group('Disconnect Message', () {
      test('Variable Header Disconnect - Defaults', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.disconnect;
        final header = MqttDisconnectVariableHeader(mHeader);
        expect(header.reasonCode, MqttDisconnectReasonCode.notSet);
        expect(header.sessionExpiryInterval, 0);
        expect(header.userProperty, isEmpty);
        expect(header.reasonString, isNull);
        expect(header.serverReference, isNull);
        expect(header.getWriteLength(), 2);
        expect(header.length, 0);
      });
      test('Variable Header Disconnect - Defaults - success', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.disconnect;
        final header = MqttDisconnectVariableHeader(mHeader);
        header.reasonCode = MqttDisconnectReasonCode.normalDisconnection;
        expect(header.sessionExpiryInterval, 0);
        expect(header.userProperty, isEmpty);
        expect(header.reasonString, isNull);
        expect(header.serverReference, isNull);
        expect(header.getWriteLength(), 0);
        expect(header.length, 0);
      });
      test('Variable Header Disconnect - Serialize', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.disconnect;
        final header = MqttDisconnectVariableHeader(mHeader);
        header.reasonCode = MqttDisconnectReasonCode.quotaExceeded;
        header.sessionExpiryInterval = 10;
        header.serverReference = 'Server Reference';
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        header.reasonString = 'Reason String';
        expect(header.getWriteLength(), 70);
        expect(header.length, 0);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          151,
          68,
          17,
          0,
          0,
          0,
          10,
          28,
          0,
          16,
          83,
          101,
          114,
          118,
          101,
          114,
          32,
          82,
          101,
          102,
          101,
          114,
          101,
          110,
          99,
          101,
          31,
          0,
          13,
          82,
          101,
          97,
          115,
          111,
          110,
          32,
          83,
          116,
          114,
          105,
          110,
          103,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
      test('Variable Header Disconnect - Deserialize - success', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.disconnect;
        mHeader.messageSize = 0;
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttDisconnectVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.reasonCode, MqttDisconnectReasonCode.normalDisconnection);
      });
      test('Variable Header Disconnect - Deserialize - full', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.disconnect;
        mHeader.messageSize = 72;
        final buffer = typed.Uint8Buffer();
        buffer.addAll([
          151,
          68,
          17,
          0,
          0,
          0,
          10,
          28,
          0,
          16,
          83,
          101,
          114,
          118,
          101,
          114,
          32,
          82,
          101,
          102,
          101,
          114,
          101,
          110,
          99,
          101,
          31,
          0,
          13,
          82,
          101,
          97,
          115,
          111,
          110,
          32,
          83,
          116,
          114,
          105,
          110,
          103,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
        final stream = MqttByteBuffer(buffer);
        final header =
            MqttDisconnectVariableHeader.fromByteBuffer(mHeader, stream);
        expect(header.length, 70);
        expect(header.reasonCode, MqttDisconnectReasonCode.quotaExceeded);
        expect(header.sessionExpiryInterval, 10);
        expect(header.serverReference, 'Server Reference');
        expect(header.userProperty[0].pairName, 'User 1 name');
        expect(header.userProperty[0].pairValue, 'User 1 value');
        expect(header.reasonString, 'Reason String');
      });
    });
    group('Authenticate Message', () {
      test('Variable Header Authenticate - Defaults', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.auth;
        final header = MqttAuthenticateVariableHeader(mHeader);
        expect(header.reasonCode, MqttAuthenticateReasonCode.notSet);
        expect(header.authenticationMethod, isNull);
        expect(header.userProperty, isEmpty);
        expect(header.reasonString, isNull);
        expect(header.authenticationData, isEmpty);
        expect(header.getWriteLength(), 0);
        expect(header.length, 0);
        expect(header.isValid, isFalse);
        header.reasonCode = MqttAuthenticateReasonCode.success;
        expect(header.isValid, isFalse);
        expect(header.getWriteLength(), 0);
        header.authenticationMethod = 'method';
        expect(header.isValid, isTrue);
        expect(header.getWriteLength(), 11);
      });
      test('Variable Header Authenticate - Serialize', () {
        final mHeader = MqttHeader();
        mHeader.messageType = MqttMessageType.auth;
        final header = MqttAuthenticateVariableHeader(mHeader);
        header.reasonCode = MqttAuthenticateReasonCode.continueAuthentication;
        header.authenticationMethod = 'method';
        header.authenticationData = typed.Uint8Buffer()..addAll([1, 2, 3, 4]);
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        properties.add(user1);
        header.userProperty = properties;
        header.reasonString = 'Reason String';
        expect(header.isValid, isTrue);
        expect(header.getWriteLength(), 62);
        expect(header.length, 0);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        header.writeTo(stream);
        expect(stream.buffer, [
          24,
          60,
          21,
          0,
          6,
          109,
          101,
          116,
          104,
          111,
          100,
          22,
          0,
          4,
          1,
          2,
          3,
          4,
          31,
          0,
          13,
          82,
          101,
          97,
          115,
          111,
          110,
          32,
          83,
          116,
          114,
          105,
          110,
          103,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
      });
    });
    test('Variable Header Authenticate - Deserialize - success', () {
      final mHeader = MqttHeader();
      mHeader.messageType = MqttMessageType.auth;
      mHeader.messageSize = 0;
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      final header =
          MqttAuthenticateVariableHeader.fromByteBuffer(mHeader, stream);
      expect(header.reasonCode, MqttAuthenticateReasonCode.success);
    });
    test('Variable Header Authenticate - Deserialize - full', () {
      final mHeader = MqttHeader();
      mHeader.messageType = MqttMessageType.auth;
      mHeader.messageSize = 62;
      final buffer = typed.Uint8Buffer();
      buffer.addAll([
        24,
        60,
        21,
        0,
        6,
        109,
        101,
        116,
        104,
        111,
        100,
        22,
        0,
        4,
        1,
        2,
        3,
        4,
        31,
        0,
        13,
        82,
        101,
        97,
        115,
        111,
        110,
        32,
        83,
        116,
        114,
        105,
        110,
        103,
        38,
        0,
        11,
        85,
        115,
        101,
        114,
        32,
        49,
        32,
        110,
        97,
        109,
        101,
        0,
        12,
        85,
        115,
        101,
        114,
        32,
        49,
        32,
        118,
        97,
        108,
        117,
        101
      ]);
      final stream = MqttByteBuffer(buffer);
      final header =
          MqttAuthenticateVariableHeader.fromByteBuffer(mHeader, stream);
      expect(header.length, 62);
      expect(
          header.reasonCode, MqttAuthenticateReasonCode.continueAuthentication);
      expect(header.authenticationMethod, 'method');
      expect(header.userProperty[0].pairName, 'User 1 name');
      expect(header.userProperty[0].pairValue, 'User 1 value');
      expect(header.reasonString, 'Reason String');
      expect(header.authenticationData, [1, 2, 3, 4]);
      expect(header.isValid, isTrue);
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
        expect(stream.buffer![0], 0);
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
        expect(willProperties.correlationData!.toList(), [1, 2, 3, 4]);
        final user1 = MqttUserProperty()
          ..pairName = 'name'
          ..pairValue = 'value';
        willProperties.userProperties = <MqttUserProperty>[user1];
        expect(willProperties.userProperties, isNotEmpty);
        expect(willProperties.userProperties[0], user1);
        expect(willProperties.getWriteLength(), 66);
        expect(willProperties.length, 65);
      });
      test('Payload - No Will Properties', () {
        final variableHeader = MqttConnectVariableHeader();
        variableHeader.connectFlags.usernameFlag = true;
        variableHeader.connectFlags.passwordFlag = true;
        final payload = MqttConnectPayload(variableHeader);
        payload.clientIdentifier = 'Client Identifier';
        payload.username = 'Username';
        payload.password = 'Password';
        expect(payload.getWriteLength(), 39);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        payload.writeTo(stream);
        expect(stream.buffer, [
          0,
          17,
          67,
          108,
          105,
          101,
          110,
          116,
          32,
          73,
          100,
          101,
          110,
          116,
          105,
          102,
          105,
          101,
          114,
          0,
          8,
          85,
          115,
          101,
          114,
          110,
          97,
          109,
          101,
          0,
          8,
          80,
          97,
          115,
          115,
          119,
          111,
          114,
          100
        ]);
      });
      test('Payload - Will Properties', () {
        final variableHeader = MqttConnectVariableHeader();
        variableHeader.connectFlags.willFlag = true;
        variableHeader.connectFlags.willQos = MqttQos.exactlyOnce;
        final payload = MqttConnectPayload(variableHeader);
        payload.clientIdentifier = 'Client Identifier';
        payload.username = 'Username';
        payload.password = 'Password';
        payload.willProperties.contentType = 'Content Type';
        payload.willProperties.willDelayInterval = 0xFF;
        payload.variableHeader!.connectFlags.willRetain = true;
        expect(payload.getWriteLength(), 40);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        payload.writeTo(stream);
        expect(stream.buffer, [
          0,
          17,
          67,
          108,
          105,
          101,
          110,
          116,
          32,
          73,
          100,
          101,
          110,
          116,
          105,
          102,
          105,
          101,
          114,
          20,
          3,
          0,
          12,
          67,
          111,
          110,
          116,
          101,
          110,
          116,
          32,
          84,
          121,
          112,
          101,
          24,
          0,
          0,
          0,
          255
        ]);
      });
    });
    group('Subscribe Message', () {
      test('Subscribe Payload - Empty', () {
        final payload = MqttSubscribePayload();
        expect(payload.isValid, isFalse);
        expect(payload.getWriteLength(), 0);
        expect(payload.count, 0);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        stream.writeByte(1);
        payload.writeTo(stream);
        expect(stream.length, 1);
      });
      test('Subscribe Payload - Topics', () {
        final payload = MqttSubscribePayload();
        final topic1 = MqttSubscriptionTopic('topic1');
        final option1 = MqttSubscriptionOption();
        option1.maximumQos = MqttQos.atLeastOnce;
        payload.addSubscription(topic1, option1);
        final topic2 = MqttSubscriptionTopic('topic2');
        payload.addSubscription(topic2);
        expect(payload.isValid, isTrue);
        expect(payload.getWriteLength(), 18);
        expect(payload.count, 2);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        payload.writeTo(stream);
        expect(stream.buffer, [
          0,
          6,
          116,
          111,
          112,
          105,
          99,
          49,
          9,
          0,
          6,
          116,
          111,
          112,
          105,
          99,
          50,
          8
        ]);
      });
    });
    group('Subscribe Ack Message', () {
      test('Subscribe Ack Payload', () {
        final messageHeader = MqttHeader();
        messageHeader.messageSize = 3;
        final varHeader = MqttSubscribeAckVariableHeader();
        final buffer = typed.Uint8Buffer();
        buffer.add(0x00);
        buffer.add(0x8f);
        buffer.add(0x97);
        final stream = MqttByteBuffer(buffer);
        final payload = MqttSubscribeAckPayload.fromByteBuffer(
            messageHeader, varHeader, stream);
        expect(payload.getWriteLength(), 0);
        expect(payload.length, 3);
        expect(payload.reasonCodes[0], MqttSubscribeReasonCode.grantedQos0);
        expect(
            payload.reasonCodes[1], MqttSubscribeReasonCode.topicFilterInvalid);
        expect(payload.reasonCodes[2], MqttSubscribeReasonCode.quotaExceeded);
        expect(stream.position, 3);
      });
    });
    group('Unsubscribe Message', () {
      test('Unsubscribe Payload', () {
        final payload = MqttUnsubscribePayload();
        expect(payload.isValid, isFalse);
        expect(payload.getWriteLength(), 0);
        payload.addStringSubscription('topic1');
        expect(payload.isValid, isTrue);
        payload.addTopicSubscription(MqttSubscriptionTopic('topic2'));
        expect(payload.getWriteLength(), 16);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        payload.writeTo(stream);
        expect(stream.buffer, [
          0,
          6,
          116,
          111,
          112,
          105,
          99,
          49,
          0,
          6,
          116,
          111,
          112,
          105,
          99,
          50
        ]);
        payload.clear();
        expect(payload.isValid, isFalse);
        expect(payload.getWriteLength(), 0);
      });
    });
    group('Unsubscribe Ack Message', () {
      test('Unsubscribe Ack Payload', () {
        final messageHeader = MqttHeader();
        messageHeader.messageSize = 3;
        final varHeader = MqttUnsubscribeAckVariableHeader();
        final buffer = typed.Uint8Buffer();
        buffer.add(0x00);
        buffer.add(0x8f);
        buffer.add(0x97);
        final stream = MqttByteBuffer(buffer);
        final payload = MqttUnsubscribeAckPayload.fromByteBuffer(
            messageHeader, varHeader, stream);
        expect(payload.getWriteLength(), 0);
        expect(payload.length, 3);
        expect(payload.reasonCodes[0], MqttSubscribeReasonCode.grantedQos0);
        expect(
            payload.reasonCodes[1], MqttSubscribeReasonCode.topicFilterInvalid);
        expect(payload.reasonCodes[2], MqttSubscribeReasonCode.quotaExceeded);
        expect(stream.position, 3);
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
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        expect(mb[1], 0x11);
      });
      test('With will set', () {
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(30)
            .startClean()
            .will()
            .withWillQos(MqttQos.atLeastOnce)
            .withWillRetain()
            .withWillTopic('willTopic');
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        expect(mb[1], 0x1D);
      });
      test('User properties', () {
        final userProp = MqttUserProperty();
        userProp.pairName = 'Name';
        userProp.pairValue = 'Value';
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(30)
            .startClean()
            .withUserProperties([userProp]);
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        expect(mb[1], 0x1F);
      });
      test('Authentication', () {
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(30)
            .startClean()
            .authenticateAs('Username', 'password');
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        expect(mb[1], 0x25);
      });
      test('Persistent session', () {
        final msg = MqttConnectMessage()
            .withClientIdentifier('mark')
            .keepAliveFor(30)
            .startSession();
        final mb = MessageSerializationHelper.getMessageBytes(msg);
        expect(mb[0], 0x10);
        expect(mb[1], 0x16);
      });
    });

    group('Connect Acknowledge', () {
      test('Deserialisation - Unspecified Error', () {
        final sampleMessage = typed.Uint8Buffer(5);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x03;
        sampleMessage[2] = 0x01; // Session Present true
        sampleMessage[3] = 0x80; // Reason Code Unspecified Error
        sampleMessage[4] = 0x00;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final message = baseMessage as MqttConnectAckMessage;
        expect(
          message.header!.duplicate,
          false,
        );
        expect(
          message.header!.retain,
          false,
        );
        expect(message.header!.qos, MqttQos.atMostOnce);
        expect(message.header!.messageType, MqttMessageType.connectAck);
        expect(message.header!.messageSize, 3);
        expect(message.variableHeader!.connectAckFlags.sessionPresent, isTrue);
        expect(message.variableHeader!.reasonCode,
            MqttConnectReasonCode.unspecifiedError);
        expect(
            MqttReasonCodeUtilities.isError(mqttConnectReasonCode
                .asInt(message.variableHeader!.reasonCode)!),
            isTrue);
      });
      test('Deserialisation - No Will Flag', () {
        final sampleMessage = typed.Uint8Buffer(11);
        sampleMessage[0] = 0x20;
        sampleMessage[1] = 0x09;
        sampleMessage[2] = 0x00; // Session Present false
        sampleMessage[3] = 0x00; // Reason Code success
        sampleMessage[4] = 0x06;
        sampleMessage[5] = 0x21; // Receive Maximum 10
        sampleMessage[6] = 0x00;
        sampleMessage[7] = 0x0a;
        sampleMessage[8] = 0x22; // Topic Alias Maximum 5
        sampleMessage[9] = 0x00;
        sampleMessage[10] = 0x05;

        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
        final message = baseMessage as MqttConnectAckMessage;
        expect(message.header!.messageType, MqttMessageType.connectAck);
        expect(message.header!.messageSize, 9);
        expect(message.variableHeader!.connectAckFlags.sessionPresent, isFalse);
        expect(
            message.variableHeader!.reasonCode, MqttConnectReasonCode.success);
        expect(
            MqttReasonCodeUtilities.isError(mqttConnectReasonCode
                .asInt(message.variableHeader!.reasonCode)!),
            isFalse);
        expect(message.variableHeader!.receiveMaximum, 10);
        expect(message.variableHeader!.topicAliasMaximum, 5);
        expect(byteBuffer.position, 0);
      });
    });

    group('Disconnect', () {
      test('Disconnect Message - Deserialisation - success', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0xe0);
        buffer.add(0x00);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(baseMessage, const TypeMatcher<MqttDisconnectMessage>());
        final message = baseMessage as MqttDisconnectMessage;
        expect(message.header!.messageType, MqttMessageType.disconnect);
        expect(message.header!.messageSize, 0);
        expect(
            message.reasonCode, MqttDisconnectReasonCode.normalDisconnection);
        expect(message.isValid, isTrue);
      });
      test('Disconnect Message - Deserialisation - full', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0xe0);
        buffer.add(0x46);
        buffer.addAll([
          151,
          68,
          17,
          0,
          0,
          0,
          10,
          28,
          0,
          16,
          83,
          101,
          114,
          118,
          101,
          114,
          32,
          82,
          101,
          102,
          101,
          114,
          101,
          110,
          99,
          101,
          31,
          0,
          13,
          82,
          101,
          97,
          115,
          111,
          110,
          32,
          83,
          116,
          114,
          105,
          110,
          103,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(baseMessage, const TypeMatcher<MqttDisconnectMessage>());
        final message = baseMessage as MqttDisconnectMessage;
        expect(message.header!.messageType, MqttMessageType.disconnect);
        expect(message.header!.messageSize, 70);
        expect(message.reasonCode, MqttDisconnectReasonCode.quotaExceeded);
        expect(message.sessionExpiryInterval, 10);
        expect(message.serverReference, 'Server Reference');
        expect(message.userProperties[0].pairName, 'User 1 name');
        expect(message.userProperties[0].pairValue, 'User 1 value');
        expect(message.reasonString, 'Reason String');
        expect(message.isValid, isTrue);
      });
      test('Disconnect Message - Serialisation - Success', () {
        final message = MqttDisconnectMessage()
            .withReasonCode(MqttDisconnectReasonCode.normalDisconnection);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer![0], 0xe0);
        expect(stream.buffer![1], 0);
        expect(message.isValid, isTrue);
      });
      test('Disconnect Message - Serialisation - Full', () {
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        final message = MqttDisconnectMessage()
            .withReasonCode(MqttDisconnectReasonCode.quotaExceeded)
            .withSessionExpiryInterval(10)
            .withServerReference('Server Reference')
            .withUserProperties([user1]).withReasonString('Reason String');

        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer![0], 0xe0);
        expect(stream.buffer![1], 70);
        expect(message.isValid, isTrue);
      });
    });

    group('Authenticate', () {
      test('Authenticate Message - Deserialisation - success', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0xf0);
        buffer.add(0x00);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(baseMessage, const TypeMatcher<MqttAuthenticateMessage>());
        final message = baseMessage as MqttAuthenticateMessage;
        expect(message.header!.messageType, MqttMessageType.auth);
        expect(message.header!.messageSize, 0);
        expect(message.reasonCode, MqttAuthenticateReasonCode.success);
        expect(message.isValid, isFalse);
        expect(message.variableHeader!.length, 0);
        expect(message.timeout, isFalse);
      });
      test('Authenticate Message - Deserialisation - full', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0xf0);
        buffer.add(0x3e);
        buffer.addAll([
          24,
          60,
          21,
          0,
          6,
          109,
          101,
          116,
          104,
          111,
          100,
          22,
          0,
          4,
          1,
          2,
          3,
          4,
          31,
          0,
          13,
          82,
          101,
          97,
          115,
          111,
          110,
          32,
          83,
          116,
          114,
          105,
          110,
          103,
          38,
          0,
          11,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          110,
          97,
          109,
          101,
          0,
          12,
          85,
          115,
          101,
          114,
          32,
          49,
          32,
          118,
          97,
          108,
          117,
          101
        ]);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(baseMessage, const TypeMatcher<MqttAuthenticateMessage>());
        final message = baseMessage as MqttAuthenticateMessage;
        expect(message.header!.messageType, MqttMessageType.auth);
        expect(message.header!.messageSize, 62);
        expect(message.reasonCode,
            MqttAuthenticateReasonCode.continueAuthentication);
        expect(message.authenticationMethod, 'method');
        expect(message.userProperties[0].pairName, 'User 1 name');
        expect(message.userProperties[0].pairValue, 'User 1 value');
        expect(message.reasonString, 'Reason String');
        expect(message.authenticationData, [1, 2, 3, 4]);
        expect(message.isValid, isTrue);
        expect(message.timeout, isFalse);
      });
      test('Authenticate Message - Serialisation - Success', () {
        final message = MqttAuthenticateMessage()
            .withReasonCode(MqttAuthenticateReasonCode.success);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer![0], 0xf0);
        expect(stream.buffer![1], 0);
        expect(message.isValid, isFalse);
      });
      test('Authenticate Message - Serialisation - Full', () {
        var user1 = MqttUserProperty();
        user1.pairName = 'User 1 name';
        user1.pairValue = 'User 1 value';
        final message = MqttAuthenticateMessage()
            .withReasonCode(MqttAuthenticateReasonCode.success)
            .withAuthenticationMethod('method')
            .withAuthenticationData(typed.Uint8Buffer()..addAll([1, 2, 3, 4]))
            .withUserProperties([user1]).withReasonString('Reason String');

        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer![0], 0xf0);
        expect(stream.buffer![1], 62);
        expect(message.isValid, isTrue);
        expect(message.timeout, isFalse);
      });
    });

    group('Ping Request', () {
      test('Serialisation', () {
        final message = MqttPingRequestMessage();
        expect(message.isValid, isTrue);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer![0], 0xc0);
        expect(stream.buffer![1], 0);
      });
    });

    group('Ping Response', () {
      test('Deserialisation', () {
        final sampleMessage = typed.Uint8Buffer(2);
        sampleMessage[0] = 0xd0;
        sampleMessage[1] = 0x00;
        final byteBuffer = MqttByteBuffer(sampleMessage);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPingResponseMessage>());
        final message = baseMessage as MqttPingResponseMessage;
        expect(message.header!.messageType, MqttMessageType.pingResponse);
      });
    });

    group('Publish', () {
      test('Deserialisation - Valid payload - No properties', () {
        final sampleMessage = <int>[
          0x30,
          0x0D,
          0x00,
          0x04, // Topic name
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00, // No properties
          'h'.codeUnitAt(0), // payload
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
        expect(baseMessage.header!.duplicate, isFalse);
        expect(baseMessage.header!.retain, isFalse);
        expect(baseMessage.header!.qos, MqttQos.atMostOnce);
        expect(baseMessage.header!.messageType, MqttMessageType.publish);
        expect(baseMessage.header!.messageSize, 13);
        final pm = baseMessage as MqttPublishMessage;
        expect(pm.variableHeader!.topicName, 'fred');
        expect(pm.variableHeader!.messageIdentifier, 0);
        expect(pm.payload.message![0], 'h'.codeUnitAt(0));
        expect(pm.payload.message![1], 'e'.codeUnitAt(0));
        expect(pm.payload.message![2], 'l'.codeUnitAt(0));
        expect(pm.payload.message![3], 'l'.codeUnitAt(0));
        expect(pm.payload.message![4], 'o'.codeUnitAt(0));
        expect(pm.payload.message![5], '!'.codeUnitAt(0));
      });
      test('Deserialisation - Valid payload - No properties - with Qos', () {
        final sampleMessage = <int>[
          0x34,
          0x0F,
          0x00,
          0x04, // Topic name
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00, // Message Identifier
          0x01,
          0x00, // No properties
          'h'.codeUnitAt(0), // payload
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
        expect(baseMessage.header!.duplicate, isFalse);
        expect(baseMessage.header!.retain, isFalse);
        expect(baseMessage.header!.qos, MqttQos.exactlyOnce);
        expect(baseMessage.header!.messageType, MqttMessageType.publish);
        expect(baseMessage.header!.messageSize, 15);
        final pm = baseMessage as MqttPublishMessage;
        expect(pm.variableHeader!.topicName, 'fred');
        expect(pm.variableHeader!.messageIdentifier, 1);
        expect(pm.payload.message![0], 'h'.codeUnitAt(0));
        expect(pm.payload.message![1], 'e'.codeUnitAt(0));
        expect(pm.payload.message![2], 'l'.codeUnitAt(0));
        expect(pm.payload.message![3], 'l'.codeUnitAt(0));
        expect(pm.payload.message![4], 'o'.codeUnitAt(0));
        expect(pm.payload.message![5], '!'.codeUnitAt(0));
      });
      test('Deserialisation - Valid payload - properties - with Qos', () {
        final sampleMessage = <int>[
          0x34,
          0x22,
          0x00,
          0x04, // Topic name
          'f'.codeUnitAt(0),
          'r'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'd'.codeUnitAt(0),
          0x00, // Message Identifier
          0x01,
          0x13, // Properties
          0x01, // Payload Format Indicator
          0x01,
          0x23, // Topic Alias
          0x00,
          0x05,
          0x26, // User property
          0x00,
          0x04,
          'n'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'm'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          0x00,
          0x05,
          'v'.codeUnitAt(0),
          'a'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'u'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'h'.codeUnitAt(0), // payload
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
        expect(baseMessage.header!.duplicate, isFalse);
        expect(baseMessage.header!.retain, isFalse);
        expect(baseMessage.header!.qos, MqttQos.exactlyOnce);
        expect(baseMessage.header!.messageType, MqttMessageType.publish);
        expect(baseMessage.header!.messageSize, 34);
        final pm = baseMessage as MqttPublishMessage;
        expect(pm.variableHeader!.topicName, 'fred');
        expect(pm.variableHeader!.messageIdentifier, 1);
        expect(pm.variableHeader!.payloadFormatIndicator, isTrue);
        expect(pm.variableHeader!.topicAlias, 5);
        expect(pm.variableHeader!.userProperty[0].pairName, 'name');
        expect(pm.variableHeader!.userProperty[0].pairValue, 'value');
        expect(pm.payload.message![0], 'h'.codeUnitAt(0));
        expect(pm.payload.message![1], 'e'.codeUnitAt(0));
        expect(pm.payload.message![2], 'l'.codeUnitAt(0));
        expect(pm.payload.message![3], 'l'.codeUnitAt(0));
        expect(pm.payload.message![4], 'o'.codeUnitAt(0));
        expect(pm.payload.message![5], '!'.codeUnitAt(0));
      });
      test('Serialisation - Valid payload - properties - with Qos', () {
        final message = MqttPublishMessage()..withQos(MqttQos.exactlyOnce);
        message.variableHeader!.topicName = 'fred';
        message.variableHeader!.payloadFormatIndicator = true;
        message.variableHeader!.messageIdentifier = 1;
        message.variableHeader!.topicAlias = 5;
        var properties = <MqttUserProperty>[];
        var user1 = MqttUserProperty();
        user1.pairName = 'name';
        user1.pairValue = 'value';
        properties.add(user1);
        message.variableHeader!.userProperty = properties;
        message.payload.message!.addAll([
          'h'.codeUnitAt(0),
          'e'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'l'.codeUnitAt(0),
          'o'.codeUnitAt(0),
          '!'.codeUnitAt(0)
        ]);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        final serializeTestBuffer = typed.Uint8Buffer()
          ..addAll([
            52,
            34,
            0,
            4,
            102,
            114,
            101,
            100,
            0,
            1,
            19,
            1,
            1,
            35,
            0,
            5,
            38,
            0,
            4,
            110,
            97,
            109,
            101,
            0,
            5,
            118,
            97,
            108,
            117,
            101,
            104,
            101,
            108,
            108,
            111,
            33
          ]);
        expect(stream.buffer, serializeTestBuffer);
      });
    });

    group('Publish Ack', () {
      test('Deserialisation - Valid', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x40);
        buffer.add(0x18);
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final byteBuffer = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishAckMessage>());
        expect(baseMessage.header!.messageType, MqttMessageType.publishAck);
        expect(baseMessage.header!.messageSize, 24);
        final bm = baseMessage as MqttPublishAckMessage;
        expect(bm.messageIdentifier, 1);
        expect(bm.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(bm.reasonString, 'abcd');
        expect(bm.userProperty[0].pairName, 'name');
        expect(bm.userProperty[0].pairValue, 'val1');
        expect(bm.variableHeader!.length, 24);
      });
      test('Serialisation - Valid', () {
        final message = MqttPublishAckMessage()
            .withMessageIdentifier(2)
            .withReasonCode(MqttPublishReasonCode.success);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer, [0x40, 0x2, 0x00, 0x2]);
      });
    });

    group('Publish Complete', () {
      test('Deserialisation - Valid', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x70);
        buffer.add(0x18);
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final byteBuffer = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishCompleteMessage>());
        expect(
            baseMessage.header!.messageType, MqttMessageType.publishComplete);
        expect(baseMessage.header!.messageSize, 24);
        final bm = baseMessage as MqttPublishCompleteMessage;
        expect(bm.messageIdentifier, 1);
        expect(bm.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(bm.reasonString, 'abcd');
        expect(bm.userProperty[0].pairName, 'name');
        expect(bm.userProperty[0].pairValue, 'val1');
        expect(bm.variableHeader.length, 24);
      });
      test('Serialisation - Valid', () {
        final message = MqttPublishCompleteMessage()
            .withMessageIdentifier(2)
            .withReasonCode(MqttPublishReasonCode.success);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer, [0x70, 0x2, 0x00, 0x2]);
      });
    });

    group('Publish Received', () {
      test('Deserialisation - Valid', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x50);
        buffer.add(0x18);
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final byteBuffer = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishReceivedMessage>());
        expect(
            baseMessage.header!.messageType, MqttMessageType.publishReceived);
        expect(baseMessage.header!.messageSize, 24);
        final bm = baseMessage as MqttPublishReceivedMessage;
        expect(bm.messageIdentifier, 1);
        expect(bm.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(bm.reasonString, 'abcd');
        expect(bm.userProperty[0].pairName, 'name');
        expect(bm.userProperty[0].pairValue, 'val1');
        expect(bm.variableHeader.length, 24);
      });
      test('Serialisation - Valid', () {
        final message = MqttPublishReceivedMessage()
            .withMessageIdentifier(2)
            .withReasonCode(MqttPublishReasonCode.success);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer, [0x50, 0x2, 0x00, 0x2]);
      });
    });

    group('Publish Release', () {
      test('Deserialisation - Valid', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x62);
        buffer.add(0x18);
        buffer.add(0); // Message Identifier
        buffer.add(1);
        buffer.add(0x80); // Reason code
        buffer.add(0x14); // Properties
        buffer.add(0x1f);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add('d'.codeUnitAt(0));
        buffer.add(0x26);
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('n'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('m'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x04);
        buffer.add('v'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('l'.codeUnitAt(0));
        buffer.add('1'.codeUnitAt(0));
        final byteBuffer = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(byteBuffer)!;
        expect(baseMessage, const TypeMatcher<MqttPublishReleaseMessage>());
        expect(baseMessage.header!.messageType, MqttMessageType.publishRelease);
        expect(baseMessage.header!.qos, MqttQos.atLeastOnce);
        expect(baseMessage.header!.messageSize, 24);
        final bm = baseMessage as MqttPublishReleaseMessage;
        expect(bm.messageIdentifier, 1);
        expect(bm.reasonCode, MqttPublishReasonCode.unspecifiedError);
        expect(bm.reasonString, 'abcd');
        expect(bm.userProperty[0].pairName, 'name');
        expect(bm.userProperty[0].pairValue, 'val1');
        expect(bm.variableHeader.length, 24);
      });
      test('Serialisation - Valid', () {
        final message = MqttPublishReleaseMessage()
            .withMessageIdentifier(2)
            .withReasonCode(MqttPublishReasonCode.success);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(stream.buffer, [0x62, 0x2, 0x00, 0x2]);
      });
    });

    group('Subscribe', () {
      test('Serialisation - Defaults', () {
        final message = MqttSubscribeMessage();
        expect(message.header!.qos, MqttQos.atLeastOnce);
        expect(message.isValid, isFalse);
        expect(message.getWriteLength(), 0);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        stream.writeShort(0x3030);
        message.writeTo(stream);
        expect(stream.position, 2);
      });
      test('Serialisation - Multi Topic With Properties', () {
        final option = MqttSubscriptionOption();
        option.retainHandling = MqttRetainHandling.sendRetained;
        option.noLocal = true;
        final user1 = MqttUserProperty();
        user1.pairName = 'User 1 Name';
        user1.pairValue = 'User 1 value';
        final user2 = MqttUserProperty();
        user2.pairName = 'User 2 Name';
        user2.pairValue = 'User 2 value';
        final message = MqttSubscribeMessage()
            .toTopic('Topic1')
            .toTopicWithQos('Topic2', MqttQos.atMostOnce)
            .toTopicWithOption('Topic3', option)
            .withSubscriptionIdentifier(0xa0)
            .withUserProperty(user1)
            .withUserProperties([user2]);
        message.messageIdentifier = 20;
        expect(message.isValid, isTrue);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(message.getWriteLength(), message.header!.messageSize + 2);
      });
    });

    group('Subscribe Ack', () {
      test('Subscribe Ack - Deserialisation', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0x90);
        buffer.add(0x1a);
        buffer.add(0x00); // Message identifier
        buffer.add(0x0a);
        buffer.add(0x14); // Property length
        buffer.add(0x1f); // Reason String
        buffer.add(0x00);
        buffer.add(0x06);
        buffer.add('r'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('s'.codeUnitAt(0));
        buffer.add('o'.codeUnitAt(0));
        buffer.add('n'.codeUnitAt(0));
        buffer.add(0x26); // User property
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('d'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('f'.codeUnitAt(0));
        buffer.add(0x00); // Payload
        buffer.add(0x8f);
        buffer.add(0x97);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(stream.length, 0);
        expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
        expect(baseMessage.header!.messageType, MqttMessageType.subscribeAck);
        expect(baseMessage.header!.messageSize, 26);
        final bm = baseMessage as MqttSubscribeAckMessage;
        expect(bm.messageIdentifier, 10);
        expect(bm.userProperty[0].pairName, 'abc');
        expect(bm.userProperty[0].pairValue, 'def');
        expect(bm.reasonString, 'reason');
        expect(bm.reasonCodes[0], MqttSubscribeReasonCode.grantedQos0);
        expect(bm.reasonCodes[1], MqttSubscribeReasonCode.topicFilterInvalid);
        expect(bm.reasonCodes[2], MqttSubscribeReasonCode.quotaExceeded);
      });
    });

    group('Unsubscribe', () {
      test('Serialisation', () {
        final subTopic = MqttSubscriptionTopic('topic2');
        final user1 = MqttUserProperty();
        user1.pairName = 'User 1 Name';
        user1.pairValue = 'User 1 value';
        final user2 = MqttUserProperty();
        user2.pairName = 'User 2 Name';
        user2.pairValue = 'User 2 value';
        final message = MqttUnsubscribeMessage()
            .withMessageIdentifier(10)
            .withUserProperty(user1)
            .withUserProperties([user2])
            .fromStringTopic('topic1')
            .fromTopic(subTopic);
        expect(message.isValid, isTrue);
        expect(message.header!.messageType, MqttMessageType.unsubscribe);
        final buffer = typed.Uint8Buffer();
        final stream = MqttByteBuffer(buffer);
        message.writeTo(stream);
        expect(message.getWriteLength(), message.header!.messageSize + 2);
      });
    });

    group('Unsubscribe Ack', () {
      test('Unsubscribe Ack - Deserialisation', () {
        final buffer = typed.Uint8Buffer();
        buffer.add(0xb0);
        buffer.add(0x1a);
        buffer.add(0x00); // Message identifier
        buffer.add(0x0a);
        buffer.add(0x14); // Property length
        buffer.add(0x1f); // Reason String
        buffer.add(0x00);
        buffer.add(0x06);
        buffer.add('r'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('a'.codeUnitAt(0));
        buffer.add('s'.codeUnitAt(0));
        buffer.add('o'.codeUnitAt(0));
        buffer.add('n'.codeUnitAt(0));
        buffer.add(0x26); // User property
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('a'.codeUnitAt(0));
        buffer.add('b'.codeUnitAt(0));
        buffer.add('c'.codeUnitAt(0));
        buffer.add(0x00);
        buffer.add(0x03);
        buffer.add('d'.codeUnitAt(0));
        buffer.add('e'.codeUnitAt(0));
        buffer.add('f'.codeUnitAt(0));
        buffer.add(0x00); // Payload
        buffer.add(0x8f);
        buffer.add(0x97);
        final stream = MqttByteBuffer(buffer);
        final baseMessage = MqttMessage.createFrom(stream)!;
        expect(stream.length, 0);
        expect(baseMessage, const TypeMatcher<MqttUnsubscribeAckMessage>());
        expect(baseMessage.header!.messageType, MqttMessageType.unsubscribeAck);
        expect(baseMessage.header!.messageSize, 26);
        final bm = baseMessage as MqttUnsubscribeAckMessage;
        expect(bm.messageIdentifier, 10);
        expect(bm.userProperty[0].pairName, 'abc');
        expect(bm.userProperty[0].pairValue, 'def');
        expect(bm.reasonString, 'reason');
        expect(bm.reasonCodes[0], MqttSubscribeReasonCode.grantedQos0);
        expect(bm.reasonCodes[1], MqttSubscribeReasonCode.topicFilterInvalid);
        expect(bm.reasonCodes[2], MqttSubscribeReasonCode.quotaExceeded);
      });
    });

    group('Unimplemented', () {
      test('Deserialisation - Invalid payload', () {
        final sampleMessage = <int>[
          0x00,
          0x02,
          0x00,
          0x04,
        ];
        final buff = typed.Uint8Buffer();
        buff.addAll(sampleMessage);
        final byteBuffer = MqttByteBuffer(buff);
        var raised = false;
        try {
          MqttMessage.createFrom(byteBuffer);
        } on Exception {
          raised = true;
        }
        expect(raised, isTrue);
      });
    });
  });
}
