/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_client;

/// MQTT reason code
///
/// A Reason Code is a one byte unsigned value that indicates the result of an operation.
/// Reason codes less than 0x80 indicate successful completion of an operation.
/// The normal Reason Code for success is 0.
/// Reason Code values of 0x80 or greater indicate failure.

/// Authentication message processing reason codes.
enum MqttAuthenticateReasonCode {
  /// Authentication is successful
  success,

  /// Continue the authentication with another step.
  continueAuthentication,

  /// Initiate a re-authentication.
  reAuthenticate,

  /// Not set indication, not part of the MQTT specification,
  /// used by the client to indicate a field has not yet been set.
  notSet
}

/// MQTT authenticate reason code support
const Map<int, MqttAuthenticateReasonCode> _mqttAuthenticateReasonCodeValues =
    <int, MqttAuthenticateReasonCode>{
  0x00: MqttAuthenticateReasonCode.success,
  0x18: MqttAuthenticateReasonCode.continueAuthentication,
  0x19: MqttAuthenticateReasonCode.reAuthenticate,
  0x0ff: MqttAuthenticateReasonCode.notSet
};

// MQTT authenticate reason code helper
MqttEnumHelper<MqttAuthenticateReasonCode?> mqttAuthenticateReasonCode =
    MqttEnumHelper<MqttAuthenticateReasonCode?>(
        _mqttAuthenticateReasonCodeValues);
