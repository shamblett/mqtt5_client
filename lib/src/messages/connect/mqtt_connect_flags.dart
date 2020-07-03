/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// Represents the connect flags part of the MQTT Variable Header
class MqttConnectFlags {
  /// Initializes a new instance of the MqttConnectFlags class.
  MqttConnectFlags();

  /// Initializes a new instance of the MqttConnectFlags class configured
  /// as per the supplied stream.
  MqttConnectFlags.fromByteBuffer(MqttByteBuffer connectFlagsStream) {
    readFrom(connectFlagsStream);
  }

  /// Clean start.
  ///
  /// This bit specifies whether the connection starts a new Session or
  /// is a continuation of an existing Session.
  /// If a Connect message is sent with Clean Start set to true, the
  /// client MUST discard any existing Session and start a new Session.
  ///
  bool cleanStart = false;

  /// Will
  ///
  /// If the Will Flag is true this indicates that a Will Message MUST be
  /// stored on the broker and associated with the Session.
  /// The Will Message consists of the Will Properties, Will Topic,
  /// and Will Payload fields in the payload.
  bool willFlag = false;

  /// Will Qos
  ///
  /// The QoS level to be used when publishing the Will Message.
  MqttQos willQos = MqttQos.atMostOnce;

  /// Will retain
  ///
  /// Specifies if the Will Message is to be retained when it is published.
  bool willRetain = false;

  /// Password present
  ///
  /// If the Password Flag is false, a Password MUST NOT be present in the payload.
  /// If the Password Flag is true, a Password MUST be present in the payload.
  /// This version of the protocol allows the sending of a password with no
  /// user name, where MQTT v3.1.1 did not. This reflects the common
  /// use of password for credentials other than a password.
  bool passwordFlag = false;

  /// Username present
  ///
  /// If the User Name Flag false, a User Name MUST NOT be present in the payload.
  /// If the User Name Flag is true, a User Name MUST be present in the payload.
  bool usernameFlag = false;

  /// Return the connect flag value
  int connectFlagByte() =>
      0 | // Reserved, must be 0
      (cleanStart ? 1 : 0) << 1 |
      (willFlag ? 1 : 0) << 2 |
      (willQos.index) << 3 |
      (willRetain ? 1 : 0) << 5 |
      (passwordFlag ? 1 : 0) << 6 |
      (usernameFlag ? 1 : 0) << 7;

  /// Writes the connect flag byte to the supplied stream.
  void writeTo(MqttByteBuffer connectFlagsStream) {
    connectFlagsStream.writeByte(connectFlagByte());
  }

  /// Reads the connect flags from the underlying stream.
  void readFrom(MqttByteBuffer stream) {
    final connectFlagsByte = stream.readByte();

    cleanStart = (connectFlagsByte & 2) == 2;
    willFlag = (connectFlagsByte & 4) == 4;
    willQos = MqttUtilities.getQosLevel((connectFlagsByte >> 3) & 3);
    willRetain = (connectFlagsByte & 32) == 32;
    passwordFlag = (connectFlagsByte & 64) == 64;
    usernameFlag = (connectFlagsByte & 128) == 128;
  }

  /// Gets the length of data written when WriteTo is called.
  static int getWriteLength() => 1;

  /// Returns a String that represents the current connect flag settings
  @override
  String toString() => 'CleanStart=$cleanStart, '
      'WillFlag=$willFlag, WillQos=${willQos.toString().split('.')[1]}, WillRetain=$willRetain, '
      'PasswordFlag=$passwordFlag, UserNameFlag=$usernameFlag';
}
