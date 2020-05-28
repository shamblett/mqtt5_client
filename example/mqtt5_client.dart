/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

/// The mqtt5_client has now been split into a server client [MqttServerClient] and a browser
/// client [MqttBrowserClient]. Example usage of these two clients are contained in this directory.
/// Example usage for a server client using secure sockets is in the mqtt5_server_client_secure.dart file.
///
/// Except for connection functionality the behavior of the clients wrt MQTT is the same.
///
/// Note that for previous users the [MqttClient] class is now only a support class and should not
/// be directly instantiated.
