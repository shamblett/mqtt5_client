/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Subscription option for a subscribe message topic
class MqttSubscriptionOption {
  /// Construction
  MqttSubscriptionOption();

  /// Maximum QoS.
  ///
  /// Gives the maximum QoS level at which the broker can send
  /// application(publish) messages to the client.
  MqttQos? maximumQos = MqttQos.atMostOnce;

  /// No Local.
  ///
  /// If true the brojer will not forward application(publish) messages to a
  /// client with a ClientID equal to the ClientID of the
  /// publishing client.
  bool noLocal = false;

  /// Retain As Published.
  ///
  /// If true, application(publish) messages forwarded using this subscription keep the
  /// retain flag they were published with. If false, application(publish) messages
  /// forwarded using this subscription have the retain flag set to false.
  bool retainAsPublished = true;

  /// Retain Handling.
  ///
  /// This option specifies whether retained messages are sent when the subscription is
  /// established. This does not affect the sending of retained messages at any
  /// point after the subscribe.
  MqttRetainHandling retainHandling = MqttRetainHandling.sendRetained;

  /// Serialize
  int serialize() {
    final maximumQos = this.maximumQos!.index;
    final noLocal = (this.noLocal ? 1 : 0) << 2;
    final retainAsPublished = (this.retainAsPublished ? 1 : 0) << 3;
    final retainHandling = this.retainHandling.index << 4;
    var byte = maximumQos + noLocal + retainAsPublished + retainHandling;
    // Bits 6 and 7 of the subscription options byte are reserved for future use
    // and must be set to 0.
    byte &= 0x3f;
    return byte;
  }

  /// Writes a subscription option to the supplied message stream.
  void writeTo(MqttByteBuffer stream) {
    stream.writeByte(serialize());
  }

  /// Write length
  int getWriteLength() => 1;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Maximum Qos = ${maximumQos.toString().split(".")[1]}');
    sb.writeln('No Local = $noLocal');
    sb.writeln('Retain As Published = $retainAsPublished');
    sb.writeln('Retain Handling = ${retainHandling.toString().split(".")[1]}');
    return sb.toString();
  }
}
