/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_test_connection_handler.dart';

@TestOn('vm')

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {}

class MockCON extends Mock implements MqttServerNormalConnection {}

// Test classes
final TestConnectionHandlerSend testCHS = TestConnectionHandlerSend();

void main() {
  group('Subscription Class', () {
    test('Default Construction', () {
      final subscription = MqttSubscription(MqttSubscriptionTopic('a/topic'));
      expect(subscription.topic.rawTopic, 'a/topic');
      expect(subscription.maximumQos, MqttQos.atMostOnce);
      expect(
          subscription.createdTime.millisecondsSinceEpoch <=
              DateTime.now().millisecondsSinceEpoch,
          isTrue);
      expect(subscription.option, isNotNull);
      expect(subscription.userProperties, isNull);
      expect(subscription.reasonCode, MqttSubscribeReasonCode.notSet);
      subscription.maximumQos = MqttQos.exactlyOnce;
      expect(subscription.maximumQos, MqttQos.exactlyOnce);
    });
    test('Default Construction With Option', () {
      final option = MqttSubscriptionOption();
      option.noLocal = true;
      option.maximumQos = MqttQos.atLeastOnce;
      final subscription =
          MqttSubscription(MqttSubscriptionTopic('a/topic'), option);
      expect(subscription.topic.rawTopic, 'a/topic');
      expect(subscription.maximumQos, MqttQos.atLeastOnce);
      expect(
          subscription.createdTime.millisecondsSinceEpoch <=
              DateTime.now().millisecondsSinceEpoch,
          isTrue);
      expect(subscription.option, isNotNull);
      expect(subscription.userProperties, isNull);
      expect(subscription.reasonCode, MqttSubscribeReasonCode.notSet);
      expect(subscription.option.noLocal, isTrue);
    });
    test('Default Construction With Maximum Qos', () {
      final subscription = MqttSubscription.withMaximumQos(
          MqttSubscriptionTopic('a/topic'), MqttQos.atMostOnce);
      expect(subscription.topic.rawTopic, 'a/topic');
      expect(subscription.maximumQos, MqttQos.atMostOnce);
      expect(
          subscription.createdTime.millisecondsSinceEpoch <=
              DateTime.now().millisecondsSinceEpoch,
          isTrue);
      expect(subscription.option, isNotNull);
      expect(subscription.userProperties, isNull);
      expect(subscription.reasonCode, MqttSubscribeReasonCode.notSet);
    });
    test('Equality', () {
      final subscription1 = MqttSubscription.withMaximumQos(
          MqttSubscriptionTopic('a/topic'), MqttQos.atMostOnce);
      final subscription2 = MqttSubscription.withMaximumQos(
          MqttSubscriptionTopic('a/topic'), MqttQos.atLeastOnce);
      final subscription3 = MqttSubscription.withMaximumQos(
          MqttSubscriptionTopic('a/nother/topic'), MqttQos.atLeastOnce);
      expect(subscription1 == subscription2, isTrue);
      expect(subscription1 == subscription3, isFalse);
    });
  });

  group('Subscription Manager - Subscribe', () {
    group('Construction', () {
      test('Default Construction', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        expect(subs.subscriptions, isEmpty);
        expect(subs.pendingSubscriptions, isEmpty);
        expect(subs.pendingUnsubscriptions, isEmpty);
        expect(subs.onSubscribed, isNull);
        expect(subs.onSubscribeFail, isNull);
        expect(subs.onUnsubscribed, isNull);
        expect(subs.getSubscriptionTopicStatus('a/topic'),
            MqttSubscriptionStatus.doesNotExist);
      });
    });
    group('Null parameters', () {
      test('Null Parameters - Subscribe', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        var exceptionCalled = true;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        try {
          subs.subscribeSubscriptionTopic(null, null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
        try {
          subs.subscribeSubscription(null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
        try {
          subs.subscribeSubscriptionList(null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
      });
      test('Null Parameters - Unsubscribe', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        var exceptionCalled = true;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        try {
          subs.unsubscribeTopic(null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
        try {
          subs.unsubscribeSubscription(null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
        try {
          subs.unsubscribeSubscriptionList(null);
          exceptionCalled = false;
        } on ArgumentError {
          expect(exceptionCalled, isTrue);
        }
      });
    });
    group('Subscribe Functionality - Pending', () {
      test('Topic Subscription request creates pending subscription', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.messageIdentifierDispenser.reset();
        final subscription = subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.subscriptions.length, 0);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1].length, 1);
        final subscriptions = subs.pendingSubscriptions[1];
        expect(subscriptions[0].topic.rawTopic, topic);
        expect(subscriptions[0].maximumQos, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(testCHS.sentMessages.length, 1);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.payload.subscriptions.length, 1);
        expect(msg.payload.subscriptions[0].topic.rawTopic, topic);
        expect(msg.payload.subscriptions[0].option.maximumQos, qos);
        final resubscription = subs.subscribeSubscriptionTopic(topic, qos);
        expect(subscription, resubscription);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1], isNotNull);
      });
      test('Subscription request creates pending subscription', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.messageIdentifierDispenser.reset();
        final subscription = MqttSubscription(MqttSubscriptionTopic(topic),
            MqttSubscriptionOption()..maximumQos = qos);
        final user1 = MqttUserProperty();
        user1.pairName = 'User 1 Name';
        user1.pairValue = 'User 1 Value';
        subscription.userProperties = [user1];
        final createdSubscription = subs.subscribeSubscription(subscription);
        expect(subs.subscriptions.length, 0);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1].length, 1);
        final subscriptions = subs.pendingSubscriptions[1];
        expect(subscriptions[0].topic.rawTopic, topic);
        expect(subscriptions[0].maximumQos, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(testCHS.sentMessages.length, 1);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.variableHeader.userProperty, isNotNull);
        expect(msg.variableHeader.userProperty.length, 1);
        expect(msg.variableHeader.userProperty[0].pairName, 'User 1 Name');
        expect(msg.variableHeader.userProperty[0].pairValue, 'User 1 Value');
        expect(msg.payload.subscriptions.length, 1);
        expect(msg.payload.subscriptions[0].topic.rawTopic, topic);
        expect(msg.payload.subscriptions[0].option.maximumQos, qos);
        final resubscription = subs.subscribeSubscriptionTopic(topic, qos);
        expect(createdSubscription, resubscription);
        expect(createdSubscription, subscription);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1], isNotNull);
      });
      test('Subscription List request creates pending subscriptions', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();
        final subscription1 = MqttSubscription(MqttSubscriptionTopic('topic1'),
            MqttSubscriptionOption()..maximumQos = MqttQos.atLeastOnce);
        final user1 = MqttUserProperty();
        user1.pairName = 'User 1 Name';
        user1.pairValue = 'User 1 Value';
        subscription1.userProperties = [user1];
        final subscription2 = MqttSubscription(MqttSubscriptionTopic('topic2'),
            MqttSubscriptionOption()..maximumQos = MqttQos.atMostOnce);
        final subscription3 = MqttSubscription(MqttSubscriptionTopic('topic3'),
            MqttSubscriptionOption()..maximumQos = MqttQos.exactlyOnce);
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.messageIdentifierDispenser.reset();
        final subscriptions = subs.subscribeSubscriptionList(
            [subscription1, subscription2, subscription3]);
        expect(subscriptions.length, 3);
        expect(subscriptions, [subscription1, subscription2, subscription3]);
        expect(subs.subscriptions.length, 0);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1].length, 3);
        final pendingSubscriptions = subs.pendingSubscriptions[1];
        expect(pendingSubscriptions[0].topic.rawTopic, 'topic1');
        expect(pendingSubscriptions[0].maximumQos, MqttQos.atLeastOnce);
        expect(subs.getSubscriptionTopicStatus('topic1'),
            MqttSubscriptionStatus.pending);
        expect(pendingSubscriptions[1].topic.rawTopic, 'topic2');
        expect(pendingSubscriptions[1].maximumQos, MqttQos.atMostOnce);
        expect(subs.getSubscriptionTopicStatus('topic2'),
            MqttSubscriptionStatus.pending);
        expect(pendingSubscriptions[2].topic.rawTopic, 'topic3');
        expect(pendingSubscriptions[2].maximumQos, MqttQos.exactlyOnce);
        expect(subs.getSubscriptionTopicStatus('topic3'),
            MqttSubscriptionStatus.pending);
        expect(testCHS.sentMessages.length, 1);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.payload.subscriptions.length, 3);
        expect(msg.payload.subscriptions[0].topic.rawTopic, 'topic1');
        expect(msg.payload.subscriptions[0].option.maximumQos,
            MqttQos.atLeastOnce);
        expect(msg.variableHeader.userProperty, isNotNull);
        expect(msg.variableHeader.userProperty.length, 1);
        expect(msg.variableHeader.userProperty[0].pairName, 'User 1 Name');
        expect(msg.variableHeader.userProperty[0].pairValue, 'User 1 Value');
        expect(msg.payload.subscriptions[1].topic.rawTopic, 'topic2');
        expect(
            msg.payload.subscriptions[1].option.maximumQos, MqttQos.atMostOnce);
        expect(msg.payload.subscriptions[2].topic.rawTopic, 'topic3');
        expect(msg.payload.subscriptions[2].option.maximumQos,
            MqttQos.exactlyOnce);
        final resubscriptions = subs.subscribeSubscriptionList(
            [subscription1, subscription2, subscription3]);
        expect(resubscriptions, isNull);
        expect(subs.pendingSubscriptions.length, 1);
        expect(subs.pendingSubscriptions[1], isNotNull);
      });
    });
    group('Subscribe Functionality - Acknowledge', () {
      test('Acknowledged subscription request creates active subscription', () {
        var cbCalled = false;
        void subCallback(MqttSubscription subscription) {
          expect(subscription.topic.rawTopic, 'testtopic');
          cbCalled = true;
        }

        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.onSubscribed = subCallback;
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isTrue);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.active);
        expect(cbCalled, isTrue);
      });
      test(
          'Acknowledged subscription request for no pending subscription is ignored',
          () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isFalse);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
      });
      test(
          'Acknowledged but failed subscription request removed pending subscription',
          () {
        var cbCalled = false;
        void subFailCallback(MqttSubscription subscription) {
          expect(subscription.topic.rawTopic, 'testtopic');
          cbCalled = true;
        }

        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.onSubscribeFail = subFailCallback;
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isFalse);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.doesNotExist);
        expect(cbCalled, isTrue);
      });
      test('Get subscription with valid topic returns subscription', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        final ret = subs.confirmSubscription(subAckMsg);
        expect(ret, isTrue);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.active);
        expect(
            subs.subscriptions[topic], const TypeMatcher<MqttSubscription>());
      });
      test('Get subscription with invalid topic returns null', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        subs.confirmSubscription(subAckMsg);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.active);
        expect(subs.subscriptions['abc_badTopic'], isNull);
      });
      test('Get subscription for pending subscription returns null', () {
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        expect(subs.subscriptions[topic], isNull);
      });
      test('Unsubscribe with ack', () {
        var cbCalled = false;
        void unsubCallback(MqttSubscription subscription) {
          expect(subscription.topic.rawTopic, 'testtopic');
          cbCalled = true;
        }

        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const topic = 'testtopic';
        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        subs.onUnsubscribed = unsubCallback;
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.pending);
        expect(
            testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
        final MqttSubscribeMessage msg = testCHS.sentMessages[0];
        expect(msg.variableHeader.messageIdentifier, 1);
        expect(msg.header.qos, MqttQos.atLeastOnce);
        expect(subs.subscriptions[topic], isNull);
        // Confirm the subscription
        final subAckMsg = MqttSubscribeAckMessage();
        subs.confirmSubscription(subAckMsg);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.active);
        // Unsubscribe
        subs.unsubscribeTopic(topic);
        expect(testCHS.sentMessages[1],
            const TypeMatcher<MqttUnsubscribeMessage>());
        final MqttUnsubscribeMessage unSub = testCHS.sentMessages[1];
        expect(unSub.variableHeader.messageIdentifier, 2);
        expect(subs.pendingUnsubscriptions.length, 1);
        expect(subs.pendingUnsubscriptions[2], topic);
        // Unsubscribe ack
        final unsubAck = MqttUnsubscribeAckMessage();
        subs.confirmUnsubscribe(unsubAck);
        expect(subs.getSubscriptionTopicStatus(topic),
            MqttSubscriptionStatus.doesNotExist);
        expect(subs.pendingUnsubscriptions.length, 0);
        expect(cbCalled, isTrue);
      });
      test('Change notification', () {
        var recCount = 0;
        const topic = 'testtopic';
        StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> st;
        // The subscription receive callback
        void subRec(List<MqttReceivedMessage<MqttMessage>> c) {
          expect(c[0].topic, topic);
          print('Change notification:: topic is $topic');
          expect(c[0].payload, const TypeMatcher<MqttPublishMessage>());
          final MqttPublishMessage recMess = c[0].payload;
          if (recCount == 0) {
            expect(recMess.variableHeader.messageIdentifier, 1);
            final pt =
                MqttUtilities.bytesToStringAsString(recMess.payload.message);
            expect(pt, 'dead');
            print('Change notification:: payload is $pt');
            expect(recMess.header.qos, MqttQos.atLeastOnce);
            recCount++;
          } else {
            expect(recMess.variableHeader.messageIdentifier, 2);
            final pt =
                MqttUtilities.bytesToStringAsString(recMess.payload.message);
            expect(pt, 'meat');
            print('Change notification:: payload is $pt');
            expect(recMess.header.qos, MqttQos.atMostOnce);
            //Stop listening
            st.cancel();
          }
        }

        // Wrap the callback
        final dynamic t1 = expectAsync1(subRec, count: 2);
        testCHS.sentMessages.clear();
        final clientEventBus = events.EventBus();

        const qos = MqttQos.atLeastOnce;
        final subs = MqttSubscriptionManager(testCHS, clientEventBus);
        subs.subscribeSubscriptionTopic(topic, qos);
        // Start listening
        st = subs.subscriptionNotifier.changes.listen(t1);
        // Publish messages on the topic
        final buff = typed.Uint8Buffer(4);
        buff[0] = 'd'.codeUnitAt(0);
        buff[1] = 'e'.codeUnitAt(0);
        buff[2] = 'a'.codeUnitAt(0);
        buff[3] = 'd'.codeUnitAt(0);
      });
    });
  });
}
