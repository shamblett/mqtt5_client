/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
@TestOn('vm')

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:typed_data/typed_data.dart' as typed;

/// Sleep function that block asynchronous activity.
/// Time units are seconds
void syncSleep(int seconds) {
  sleep(Duration(seconds: seconds));
}

void main() {
  group('Exceptions', () {
    test('Client Identifier', () {
      const clid =
          'ThisCLIDisMorethan1024characterslongvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'
          'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
      final exception = MqttIdentifierException(clid);
      expect(
          exception.toString(),
          'mqtt-client::ClientIdentifierException: Client id $clid is too long at ${clid.length}, '
          'Maximum ClientIdentifier length is ${MqttConstants.maxClientIdentifierLength}');
    });
    test('Connection', () {
      const state = MqttConnectionState.disconnected;
      final exception = MqttConnectionException(state);
      expect(
          exception.toString(),
          'mqtt-client::ConnectionException: The connection must be in the Connected state in '
          'order to perform this operation. Current state is disconnected');
    });
    test('No Connection', () {
      final exception = MqttNoConnectionException('the message');
      expect(exception.toString(),
          'mqtt-client::NoConnectionException: the message');
    });
    test('Invalid Header', () {
      const message = 'Corrupt Header Packet';
      final exception = MqttInvalidHeaderException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidHeaderException: $message');
    });
    test('Invalid Message', () {
      const message = 'Corrupt Message Packet';
      final exception = MqttInvalidMessageException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidMessageException: $message');
    });
    test('Invalid Payload Size', () {
      const size = 2000;
      const max = 1000;
      final exception = MqttInvalidPayloadSizeException(size, max);
      expect(
          exception.toString(),
          'mqtt-client::InvalidPayloadSizeException: The size of the payload ($size bytes) must '
          'be equal to or greater than 0 and less than $max bytes');
    });
    test('Invalid Topic', () {
      const message = 'Too long';
      const topic = 'kkkk-yyyy';
      final exception = MqttInvalidTopicException(message, topic);
      expect(exception.toString(),
          'mqtt-client::InvalidTopicException: Topic $topic is $message');
    });
    test('Invalid Instantiation', () {
      final exception = MqttIncorrectInstantiationException();
      expect(
          exception.toString(),
          'mqtt-client::ClientIncorrectInstantiationException: Incorrect instantiation, do not'
          'instantiate MqttClient directly, use MqttServerClient or MqttBrowserClient');
    });
  });

  group('Publication Topic', () {
    test('Min length', () {
      const topic = '';
      var raised = false;
      try {
        final pubTopic = MqttPublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::Topic: rawTopic must contain at least one character');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Max length', () {
      var raised = false;
      final sb = StringBuffer();
      for (var i = 0; i < MqttTopic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      try {
        final topic = sb.toString();
        final pubTopic = MqttPublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::Topic: The length of the supplied rawTopic '
            '(65536) is longer than the maximum allowable (${MqttTopic.maxTopicLength})');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Wildcards', () {
      const topic = MqttTopic.wildcard;
      var raised = false;
      try {
        final pubTopic = MqttPublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::PublicationTopic: Cannot publish to a topic that '
            'contains MQTT topic wildcards (# or +)');
        raised = true;
      }
      expect(raised, isTrue);
      raised = false;
      const topic1 = MqttTopic.multiWildcard;
      try {
        final pubTopic1 = MqttPublicationTopic(topic1);
        print(pubTopic1.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::PublicationTopic: Cannot publish to a topic '
            'that contains MQTT topic wildcards (# or +)');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Valid', () {
      const topic = 'AValidTopic';
      final pubTopic = MqttPublicationTopic(topic);
      expect(pubTopic.hasWildcards, false);
      expect(pubTopic.rawTopic, topic);
      expect(pubTopic.toString(), topic);
      final pubTopic1 = MqttPublicationTopic(topic);
      expect(pubTopic1, pubTopic);
      expect(pubTopic1.hashCode, pubTopic.hashCode);
      final pubTopic2 = MqttPublicationTopic('DDDDDDD');
      expect(pubTopic.hashCode, isNot(equals(pubTopic2.hashCode)));
    });
  });

  group('Subscription Topic', () {
    test('Invalid multiWildcard at end', () {
      const topic = 'invalidEnding#';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: Topics using the # wildcard longer than 1 character must '
            'be immediately preceeded by a the rawTopic separator /');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('MultiWildcard in middle', () {
      const topic = 'a/#/topic';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one MultiWildcard in single fragment', () {
      const topic = 'a/##/topic';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one type of Wildcard in single fragment', () {
      const topic = 'a/#+/topic';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one Wildcard in single fragment', () {
      const topic = 'a/++/topic';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a '
            'wildcard but is more than one character long');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than just Wildcard in fragment', () {
      const topic = 'a/frag+/topic';
      var raised = false;
      try {
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a '
            'wildcard but is more than one character long');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Max length', () {
      final sb = StringBuffer();
      for (var i = 0; i < MqttTopic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      var raised = false;
      try {
        final topic = sb.toString();
        final subTopic = MqttSubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::Topic: The length of the supplied rawTopic '
            '(65536) is longer than the maximum allowable (${MqttTopic.maxTopicLength})');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test(
        'MultiWildcard at end of topic is valid when preceeded by topic separator',
        () {
      const topic = 'a/topic/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No Wildcards of any type is valid', () {
      const topic = 'a/topic/with/no/wildcard/is/good';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No separators is valid', () {
      const topic = 'ATopicWithNoSeparators';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('Single level equal topics match', () {
      const topic = 'finance';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic(topic)), isTrue);
    });
    test('MultiWildcard only topic matches any random', () {
      const topic = '#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard only topic matches topic starting with separator', () {
      const topic = '#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(
          subTopic.matches(MqttPublicationTopic('/finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard at end matches topic that does not match same depth',
        () {
      const topic = 'finance/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance')), isTrue);
    });
    test('MultiWildcard at end matches topic with anything at Wildcard level',
        () {
      const topic = 'finance/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance/ibm')), isTrue);
    });
    test('Single Wildcard at end matches anything in same level', () {
      const topic = 'finance/+/closingprice';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test(
        'More than one single Wildcard at different levels matches topic with any value at those levels',
        () {
      const topic = 'finance/+/closingprice/month/+';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(
          subTopic.matches(
              MqttPublicationTopic('finance/ibm/closingprice/month/october')),
          isTrue);
    });
    test(
        'Single and MultiWildcard matches topic with any value at those levels and deeper',
        () {
      const topic = 'finance/+/closingprice/month/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(
          subTopic.matches(MqttPublicationTopic(
              'finance/ibm/closingprice/month/october/2014')),
          isTrue);
    });
    test('Single Wildcard matches topic empty fragment at that point', () {
      const topic = 'finance/+/closingprice';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance//closingprice')),
          isTrue);
    });
    test(
        'Single Wildcard at end matches topic with empty last fragment at that spot',
        () {
      const topic = 'finance/ibm/+';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance/ibm/')), isTrue);
    });
    test('Single level non equal topics do not match', () {
      const topic = 'finance';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('money')), isFalse);
    });
    test('Single Wildcard at end does not match topic that goes deeper', () {
      const topic = 'finance/+';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance/ibm/closingprice')),
          isFalse);
    });
    test(
        'Single Wildcard at end does not match topic that does not contain anything at same level',
        () {
      const topic = 'finance/+';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('finance')), isFalse);
    });
    test('Multi level non equal topics do not match', () {
      const topic = 'finance/ibm/closingprice';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(
          subTopic.matches(MqttPublicationTopic('some/random/topic')), isFalse);
    });
    test('different length topics do not match and do not throw range error',
        () {
      const topic = 'finance/ibm/closingprice/+/topic/sub';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(
          subTopic
              .matches(MqttPublicationTopic('finance/ibm/closingprice/sub')),
          isFalse);
    });
    test(
        'MultiWildcard does not match topic with difference before Wildcard level',
        () {
      const topic = 'finance/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('money/ibm')), isFalse);
    });
    test('Topics differing only by case do not match', () {
      const topic = 'finance';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.matches(MqttPublicationTopic('Finance')), isFalse);
    });
    test('To string', () {
      const topic = 'finance';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(topic, subTopic.toString());
    });
    test('Wildcard', () {
      const topic = 'finance/+';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('MultiWildcard', () {
      const topic = 'finance/#';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('No Wildcard', () {
      const topic = 'finance';
      final subTopic = MqttSubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isFalse);
    });
  });

  group('Subscription Options', () {
    test('Subscription Options - Default', () {
      final option = MqttSubscriptionOption();
      expect(option.getWriteLength(), 1);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      option.writeTo(stream);
      expect(stream.buffer![0], 0x8);
    });
    test('Subscription Options - All Set', () {
      final option = MqttSubscriptionOption();
      option.maximumQos = MqttQos.exactlyOnce;
      option.noLocal = true;
      option.retainAsPublished = false;
      option.retainHandling = MqttRetainHandling.doNotSendRetained;
      expect(option.getWriteLength(), 1);
      final buffer = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buffer);
      option.writeTo(stream);
      expect(stream.buffer![0], 0x26);
    });
  });

  group('Encoding', () {
    group('UTF8', () {
      test('Get bytes', () {
        final enc = MqttUtf8Encoding();
        final bytes = enc.toUtf8('abc');
        expect(bytes.length, 5);
        expect(bytes[0], 0);
        expect(bytes[1], 3);
        expect(bytes[2], 'a'.codeUnits[0]);
        expect(bytes[3], 'b'.codeUnits[0]);
        expect(bytes[4], 'c'.codeUnits[0]);
      });
      test('Get byte count', () {
        final enc = MqttUtf8Encoding();
        final byteCount = enc.byteCount('abc');
        expect(byteCount, 5);
      });
      test('Get string', () {
        final enc = MqttUtf8Encoding();
        final buff = enc.toUtf8('abc');
        final message = enc.fromUtf8(buff);
        expect(message, 'abc');
      });
      test('Get char count valid length LSB', () {
        final enc = MqttUtf8Encoding();
        final buff = typed.Uint8Buffer(5);
        buff[0] = 0;
        buff[1] = 3;
        buff[2] = 'a'.codeUnits[0];
        buff[3] = 'b'.codeUnits[0];
        buff[4] = 'c'.codeUnits[0];
        final count = enc.length(buff);
        expect(count, 3);
      });
      test('Get char count valid length MSB', () {
        final enc = MqttUtf8Encoding();
        final buff = typed.Uint8Buffer(2);
        buff[0] = 0xFF;
        buff[1] = 0xFF;
        final count = enc.length(buff);
        expect(count, 65535);
      });
      test('Get char count invalid length', () {
        final enc = MqttUtf8Encoding();
        var raised = false;
        final buff = typed.Uint8Buffer(1);
        buff[0] = 0;
        try {
          enc.length(buff);
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttUtf8Encoding:: Length byte array must comprise 2 bytes');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('Control characters initiate failure 1', () {
        final enc = MqttUtf8Encoding();
        var raised = false;
        final buff = Uint8Buffer();
        buff.add(0);
        buff.add(4);
        buff.addAll((Utf8Codec().encoder.convert('ab\u{0088}').toList()));
        try {
          enc.fromUtf8(buff);
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttUtf8Encoding:: UTF8 string is invalid, contains control characters');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('Control characters initiate failure 2', () {
        final enc = MqttUtf8Encoding();
        var raised = false;
        final buff = Uint8Buffer();
        buff.add(0);
        buff.add(3);
        buff.addAll((Utf8Codec().encoder.convert('ab\u{0004}').toList()));
        try {
          enc.fromUtf8(buff);
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttUtf8Encoding:: UTF8 string is invalid, contains control characters');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('Normative example', () {
        final enc = MqttUtf8Encoding();
        var encoded = enc.toUtf8('A𪛔');
        final count = enc.length(encoded);
        expect(count, 5);
        expect(encoded.toList(), [0x00, 0x05, 0x41, 0xf0, 0xaa, 0x9b, 0x94]);
      });
    });
    group('Variable Byte Integer', () {
      test('toInt - Null Byte Array', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        try {
          enc.toInt(null);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::toInt byte integer is null or empty');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toInt - Empty Byte Array', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        var buff = typed.Uint8Buffer();
        try {
          enc.toInt(buff);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::toInt byte integer is null or empty');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toInt - Byte Array Too Long', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        var buff = typed.Uint8Buffer(5)..fillRange(0, 4, 0x80);
        try {
          enc.toInt(buff);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::toInt invalid byte sequence [128, 128, 128, 128, 0]');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toInt - One Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var buff = typed.Uint8Buffer(1);
        buff[0] = 0x08;
        var res = enc.toInt(buff);
        expect(res, 8);
        expect(enc.length(8), 1);
      });
      test('toInt - Two Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var buff = typed.Uint8Buffer(2);
        buff[0] = 0x80;
        buff[1] = 0x70;
        var res = enc.toInt(buff);
        expect(res, 14336);
        expect(enc.length(14336), 2);
      });
      test('toInt - Three Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var buff = typed.Uint8Buffer(3);
        buff[0] = 0x80;
        buff[1] = 0x80;
        buff[2] = 0x70;
        var res = enc.toInt(buff);
        expect(res, 1835008);
        expect(enc.length(1835008), 3);
      });
      test('toInt - Four Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var buff = typed.Uint8Buffer(4);
        buff[0] = 0x80;
        buff[1] = 0x80;
        buff[2] = 0x80;
        buff[3] = 0x70;
        var res = enc.toInt(buff);
        expect(res, 234881024);
        expect(enc.length(234881024), 4);
      });
      test('toInt - Invalid Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        var buff = typed.Uint8Buffer(1);
        buff[0] = 0xaa;
        try {
          enc.toInt(buff);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::toInt invalid byte sequence [170]');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('fromInt - Value Too High', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        var value = MqttVariableByteIntegerEncoding.maxConvertibleValue + 1;
        try {
          enc.fromInt(value);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::fromInt supplied value is not convertible 268435456');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('fromInt - Value Negative', () {
        var enc = MqttVariableByteIntegerEncoding();
        var raised = false;
        var value = -10;
        try {
          enc.fromInt(value);
        } on Error catch (error) {
          expect(error.toString(),
              'Invalid argument(s): MqttByteIntegerEncoding::fromInt supplied value is not convertible -10');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('fromInt - One Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var res = enc.fromInt(8);
        expect(res.toList(), [8]);
      });
      test('fromInt - Two Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var res = enc.fromInt(14336);
        expect(res.toList(), [0x80, 0x70]);
      });
      test('fromInt - Three Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var res = enc.fromInt(1835008);
        expect(res.toList(), [0x80, 0x80, 0x70]);
      });
      test('fromInt - Four Byte Value', () {
        var enc = MqttVariableByteIntegerEncoding();
        var res = enc.fromInt(234881024);
        expect(res.toList(), [0x80, 0x80, 0x80, 0x70]);
      });
      test('Reversible', () {
        var enc = MqttVariableByteIntegerEncoding();
        const val = 10000;
        var res = enc.fromInt(val);
        var intRes = enc.toInt(res);
        expect(intRes, val);
      });
    });
    group('BinaryData, ()', () {
      test('toBinaryData - Null', () {
        var enc = MqttBinaryDataEncoding();
        var raised = false;
        try {
          enc.toBinaryData(null);
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttBinaryDataEncoding::toBinaryData  -  data is null or empty');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toBinaryData - Empty', () {
        var enc = MqttBinaryDataEncoding();
        var raised = false;
        try {
          enc.toBinaryData(typed.Uint8Buffer());
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttBinaryDataEncoding::toBinaryData  -  data is null or empty');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toBinaryData - Invalid Length Bytes', () {
        var enc = MqttBinaryDataEncoding();
        var raised = false;
        try {
          enc.toBinaryData(typed.Uint8Buffer(65536));
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttBinaryDataEncoding::toBinaryData  -  data length is invalid, length is 65536');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('toBinaryData - Valid', () {
        var enc = MqttBinaryDataEncoding();
        var buff = typed.Uint8Buffer(3);
        buff[0] = 1;
        buff[1] = 2;
        buff[2] = 3;
        var res = enc.toBinaryData(buff);
        expect(res.toList(), [0, 3, 1, 2, 3]);
      });
      test('fromBinaryData - Invalid Length Bytes', () {
        var enc = MqttBinaryDataEncoding();
        var raised = false;
        var buff = typed.Uint8Buffer(1);
        try {
          enc.fromBinaryData(buff);
        } on Exception catch (exception) {
          expect(exception.toString(),
              'Exception: MqttBinaryDataEncoding::length length byte array must comprise 2 bytes');
          raised = true;
        }
        expect(raised, isTrue);
      });
      test('fromBinaryData - Valid', () {
        var enc = MqttBinaryDataEncoding();
        var buff = typed.Uint8Buffer(5);
        buff[0] = 0;
        buff[1] = 3;
        buff[2] = 1;
        buff[3] = 2;
        buff[4] = 3;
        var res = enc.fromBinaryData(buff);
        expect(res.toList(), [1, 2, 3]);
      });
    });
  });

  group('Utility', () {
    test('Protocol', () {
      expect(MqttProtocol.version, MqttConstants.mqttProtocolVersion);
      expect(MqttProtocol.name, MqttConstants.mqttProtocolName);
    });
    test('Byte Buffer', () {
      final uBuff = typed.Uint8Buffer(10);
      final uBuff1 = typed.Uint8Buffer(10);
      final buff = MqttByteBuffer(uBuff);
      expect(buff.length, 10);
      expect(buff.position, 0);
      buff.readByte();
      buff.readShort();
      expect(buff.position, 3);
      final tmpBuff = buff.read(4);
      expect(tmpBuff.length, 4);
      expect(buff.position, 7);
      buff.writeByte(1);
      buff.writeShort(2);
      expect(buff.position, 10);
      buff.write(uBuff);
      expect(buff.length, 20);
      expect(buff.position, 20);
      buff.buffer = null;
      buff.write(uBuff1);
      expect(buff.length, 10);
      expect(buff.position, 10);
      final bytes = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final buff1 = MqttByteBuffer.fromList(bytes);
      expect(buff1.length, 10);
      expect(buff1.position, 0);
      expect(buff1.peekByte(), 1);
      buff1.seek(20);
      expect(buff1.position, 10);
    });
    test('Sleep Async', () async {
      final start = DateTime.now();
      await MqttUtilities.asyncSleep(1);
      final end = DateTime.now();
      final difference = end.difference(start);
      expect(difference.inSeconds, 1);
    });
    test('Sleep Sync', () {
      final start = DateTime.now();
      syncSleep(1);
      final end = DateTime.now();
      final difference = end.difference(start);
      expect(difference.inSeconds, 1);
    });
    test('Get Qos Level', () {
      var qos = MqttUtilities.getQosLevel(0);
      expect(qos, MqttQos.atMostOnce);
      qos = MqttUtilities.getQosLevel(1);
      expect(qos, MqttQos.atLeastOnce);
      qos = MqttUtilities.getQosLevel(2);
      expect(qos, MqttQos.exactlyOnce);
      qos = MqttUtilities.getQosLevel(0x80);
      expect(qos, MqttQos.failure);
      qos = MqttUtilities.getQosLevel(0x55);
      expect(qos, MqttQos.reserved1);
    });
  });

  group('Payload builder', () {
    test('Construction', () {
      final builder = MqttPayloadBuilder();
      expect(builder.payload, isNotNull);
      expect(builder.length, 0);
    });

    test('Add buffer', () {
      final builder = MqttPayloadBuilder();
      final buffer = typed.Uint8Buffer()..addAll(<int>[1, 2, 3]);
      builder.addBuffer(buffer);
      expect(builder.length, 3);
      expect(builder.payload, buffer);
    });

    test('Add byte', () {
      final builder = MqttPayloadBuilder();
      builder.addByte(129);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[129]);
    });

    test('Add byte - overflow', () {
      final builder = MqttPayloadBuilder();
      builder.addByte(300);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[44]);
    });

    test('Add bool', () {
      final builder = MqttPayloadBuilder();
      builder.addBool(val: true);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[1]);
      builder.addBool(val: false);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[1, 0]);
    });

    test('Add half', () {
      final builder = MqttPayloadBuilder();
      builder.addHalf(18000);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[0x50, 0x46]);
    });

    test('Add half - overflow', () {
      final builder = MqttPayloadBuilder();
      builder.addHalf(65539);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[0x3, 0x00]);
    });

    test('Add word', () {
      final builder = MqttPayloadBuilder();
      builder.addWord(123456789);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x15, 0xCD, 0x5B, 0x07]);
    });

    test('Add word - overflow', () {
      final builder = MqttPayloadBuilder();
      builder.addWord(4294967298);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x2, 0x00, 0x00, 0x00]);
    });

    test('Add int', () {
      final builder = MqttPayloadBuilder();
      builder.addInt(123456789030405);
      expect(builder.length, 8);
      expect(builder.payload!.toList(),
          <int>[0x05, 0x26, 0x0E, 0x86, 0x48, 0x70, 0x00, 0x00]);
    });

    test('Add string', () {
      final builder = MqttPayloadBuilder();
      builder.addString('Hello');
      expect(builder.length, 5);
      expect(builder.payload!.toList(), <int>[72, 101, 108, 108, 111]);
    });

    test('Add unicode string', () {
      final builder = MqttPayloadBuilder();
      builder.addUTF16String('\u{1D11E}');
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x34, 0xD8, 0x1E, 0xDD]);
    });

    test('Add emoji', () {
      final builder = MqttPayloadBuilder();
      builder.addUTF16String('😁');
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x3D, 0xD8, 0x1, 0xDE]);
    });

    test('Add arabic', () {
      final builder = MqttPayloadBuilder();
      const arabic = 'سلام';
      builder.addUTF16String(arabic);
      expect(builder.length, 8);
      expect(builder.payload!.toList(),
          <int>[0x33, 0x06, 0x44, 0x06, 0x27, 0x06, 0x45, 0x06]);
    });

    test('Add arabic string', () {
      final builder = MqttPayloadBuilder();
      const arabic = 'این یک پیام تستی هستش';
      builder.addString(arabic);
      expect(builder.length, 38);
      expect(builder.payload!.toList(), <int>[
        0x27,
        0x06,
        0xCC,
        0x06,
        0x46,
        0x06,
        0x20,
        0xCC,
        0x06,
        0xA9,
        0x06,
        0x20,
        0x7E,
        0x06,
        0xCC,
        0x06,
        0x27,
        0x06,
        0x45,
        0x06,
        0x20,
        0x2A,
        0x06,
        0x33,
        0x06,
        0x2A,
        0x06,
        0xCC,
        0x06,
        0x020,
        0x47,
        0x06,
        0x33,
        0x06,
        0x2A,
        0x06,
        0x34,
        0x06
      ]);
    });

    test('Add UTF8 string', () {
      final builder = MqttPayloadBuilder();
      builder.addUTF8String(json
          .encode(<String, String>{'type': 'msgText', 'data': 'تست 😀 😁 '}));
      expect(builder.length, 45);
      expect(builder.payload!.toList(), <int>[
        123,
        34,
        116,
        121,
        112,
        101,
        34,
        58,
        34,
        109,
        115,
        103,
        84,
        101,
        120,
        116,
        34,
        44,
        34,
        100,
        97,
        116,
        97,
        34,
        58,
        34,
        216,
        170,
        216,
        179,
        216,
        170,
        32,
        240,
        159,
        152,
        128,
        32,
        240,
        159,
        152,
        129,
        32,
        34,
        125
      ]);
    });

    test('Add Will payload', () {
      final builder = MqttPayloadBuilder();
      builder.addWillPayload('{"message":"bye"}');
      expect(builder.length, 19);
      expect(builder.payload!.toList(), <int>[
        0,
        17,
        123,
        34,
        109,
        101,
        115,
        115,
        97,
        103,
        101,
        34,
        58,
        34,
        98,
        121,
        101,
        34,
        125
      ]);
    });

    test('Add half double', () {
      final builder = MqttPayloadBuilder();
      builder.addHalfDouble(10000.5);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0, 66, 28, 70]);
    });

    test('Add double', () {
      final builder = MqttPayloadBuilder();
      builder.addDouble(1.5e43);
      expect(builder.length, 8);
      expect(
          builder.payload!.toList(), <int>[91, 150, 146, 56, 33, 134, 229, 72]);
    });

    test('Clear', () {
      final builder = MqttPayloadBuilder();
      builder.addString('Hello');
      expect(builder.length, 5);
      builder.clear();
      expect(builder.length, 0);
    });
  });

  group('Cancellable async timer', () {
    test('Normal expiry', () async {
      final start = DateTime.now();
      final sleeper = MqttCancellableAsyncSleep(200);
      expect(sleeper.isRunning, false);
      expect(sleeper.timeout, 200);
      await sleeper.sleep();
      expect(sleeper.isRunning, false);
      final now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  const Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          true);
      expect(sleeper.isRunning, false);
    });
    test('Normal expiry - check', () async {
      final start = DateTime.now();
      final sleeper = MqttCancellableAsyncSleep(100);
      await sleeper.sleep();
      final now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  const Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          false);
    });

    test('Cancel', () async {
      final sleeper = MqttCancellableAsyncSleep(200);
      void action() {
        sleeper.cancel();
        expect(sleeper.isRunning, false);
      }

      final start = DateTime.now();
      Future<void>.delayed(const Duration(milliseconds: 100), action);
      await sleeper.sleep();
      final now = DateTime.now();
      expect(now.millisecondsSinceEpoch - start.millisecondsSinceEpoch < 200,
          true);
    });
  });

  group('Mqtt Client', () {
    test('Invalid instantiation', () async {
      var ok = false;
      try {
        var client = MqttClient('aaaa', 'bbbb');
        await client.connect();
      } on MqttIncorrectInstantiationException {
        ok = true;
      }
      expect(ok, isTrue);
    });
    test('Client Id ', () {
      final client = MqttClient('aaaa', 'bbbb');
      expect(
          client
              .getConnectMessage('username', 'password')
              .payload
              .clientIdentifier,
          'bbbb');
      final userConnect = MqttConnectMessage().withClientIdentifier('cccc');
      client.connectionMessage = userConnect;
      expect(
          client
              .getConnectMessage('username', 'password')
              .payload
              .clientIdentifier,
          'cccc');
    });
  });

  group('Logging', () {
    test('Logging off', () {
      MqttLogger.testMode = true;
      MqttLogger.log('No output');
      expect(MqttLogger.testOutput, '');
    });
    test('Logging on - normal', () {
      MqttLogger.testMode = true;
      MqttLogger.loggingOn = true;
      MqttLogger.log('Some output');
      expect(MqttLogger.testOutput.isNotEmpty, isTrue);
      expect(MqttLogger.testOutput.contains('Some output'), isTrue);
    });
    test('Logging on - optimised', () {
      MqttLogger.testMode = true;
      MqttLogger.loggingOn = true;
      final message = MqttSubscribeAckMessage();
      MqttLogger.log('Some output - ', message);
      expect(MqttLogger.testOutput.isNotEmpty, isTrue);
      expect(MqttLogger.testOutput.contains('Some output'), isTrue);
      expect(MqttLogger.testOutput.contains('MqttMessageType.subscribeAck'),
          isTrue);
    });
  });
}
