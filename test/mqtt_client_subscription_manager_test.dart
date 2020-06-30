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

final TestConnectionHandlerNoSend testCHNS = TestConnectionHandlerNoSend();
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

  group('Manager', () {
    test('Invalid topic returns null subscription', () {
      var cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'house#');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'house#';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.onSubscribeFail = subCallback;
      final ret = subs.subscribeSubscription(topic, qos);
      expect(ret, isNull);
      expect(cbCalled, isTrue);
    });
    test('Subscription request creates pending subscription', () {
      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
    });
    test('Acknowledged subscription request creates active subscription', () {
      var cbCalled = false;
      void subCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.onSubscribed = subCallback;
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
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
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isFalse);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
    });
    test(
        'Acknowledged but failed subscription request removed pending subscription',
        () {
      var cbCalled = false;
      void subFailCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.onSubscribeFail = subFailCallback;
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isFalse);
      expect(subs.getSubscriptionsStatus(topic),
          MqttSubscriptionStatus.doesNotExist);
      expect(cbCalled, isTrue);
    });
    test('Get subscription with valid topic returns subscription', () {
      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      final ret = subs.confirmSubscription(subAckMsg);
      expect(ret, isTrue);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      expect(subs.subscriptions[topic], const TypeMatcher<MqttSubscription>());
    });
    test('Get subscription with invalid topic returns null', () {
      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      expect(subs.subscriptions['abc_badTopic'], isNull);
    });
    test('Get subscription for pending subscription returns null', () {
      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.subscribeSubscription(topic, qos);
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
    });
    test('Unsubscribe with ack', () {
      var cbCalled = false;
      void unsubCallback(String topic) {
        expect(topic, 'testtopic');
        cbCalled = true;
      }

      testCHS.sentMessages.clear();
      final clientEventBus = events.EventBus();

      const topic = 'testtopic';
      const qos = MqttQos.atLeastOnce;
      final subs = MqttSubscriptionManager(testCHS, clientEventBus);
      subs.subscribeSubscription(topic, qos);
      subs.onUnsubscribed = unsubCallback;
      expect(
          subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.pending);
      expect(
          testCHS.sentMessages[0], const TypeMatcher<MqttSubscribeMessage>());
      final MqttSubscribeMessage msg = testCHS.sentMessages[0];
      expect(msg.variableHeader.messageIdentifier, 1);
      expect(msg.header.qos, MqttQos.atLeastOnce);
      expect(subs.subscriptions[topic], isNull);
      // Confirm the subscription
      final subAckMsg = MqttSubscribeAckMessage();
      subs.confirmSubscription(subAckMsg);
      expect(subs.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
      // Unsubscribe
      subs.unsubscribe(topic);
      expect(
          testCHS.sentMessages[1], const TypeMatcher<MqttUnsubscribeMessage>());
      final MqttUnsubscribeMessage unSub = testCHS.sentMessages[1];
      expect(unSub.variableHeader.messageIdentifier, 2);
      expect(subs.pendingUnsubscriptions.length, 1);
      expect(subs.pendingUnsubscriptions[2], topic);
      // Unsubscribe ack
      final unsubAck = MqttUnsubscribeAckMessage();
      subs.confirmUnsubscribe(unsubAck);
      expect(subs.getSubscriptionsStatus(topic),
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
      subs.subscribeSubscription(topic, qos);
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
}
