/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

/// The mqtt5_client comprises a server client [MqttServerClient] and a browser
/// client [MqttBrowserClient]. Example usage of these two clients are contained in this directory.
///
/// Except for connection functionality the behavior of the clients wrt MQTT is the same.
///
/// Note that for previous users the [MqttClient] class is now only a support class and should not
/// be directly instantiated.
/// See the example mqtt5_universal_client to see how instantiating a server or browser client as
/// needed can be done automatically.
