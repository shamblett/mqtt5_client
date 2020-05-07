# mqtt5_client
[![Build Status](https://travis-ci.org/shamblett/mqtt_client.svg?branch=master)](https://travis-ci.org/shamblett/mqtt_client)

A server and browser based MQTT 5 client for Dart.

The client is an MQTT v5 implementation supporting subscription/publishing at all QOS levels,
keep alive and synchronous connection. The client is designed to take as much MQTT protocol work
off the user as possible, connection protocol is handled automatically as are the message exchanges needed
to support the different QOS levels and the keep alive mechanism. This allows the user to concentrate on
publishing/subscribing and not the details of MQTT itself.

Examples of usage can be found in the examples directory.  An example is also provided
showing how to use the client to connect to the mqtt-bridge of Google's IoT-Core suite. This demonstrates
how to use secure connections and switch MQTT protocols. The test directory also contains standalone runnable scripts demonstrating subscription, publishing and topic filtering.

The server client supports both normal and secure TCP connections and secure(wss) and non-secure(ws) websocket connections.
The browser client supports only secure(wss) and non-secure(ws) websocket connections.


Please read the changelog for details related to specific versions.

# Under Construction - not for production use
