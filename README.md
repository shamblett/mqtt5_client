# mqtt5_client
[![Build Status](https://github.com/shamblett/mqtt5_client/actions/workflows/ci.yml/badge.svg)](https://github.com/shamblett/mqtt5_client/actions/workflows/ci.yml)

A server and browser based MQTT Version 5 client for Dart.

The client is an MQTT Version 5 implementation supporting subscription/publishing at all QOS levels,
authentication, 
keep alive and synchronous connection. The client is designed to take as much MQTT protocol work
off the user as possible, connection protocol is handled automatically as are the message exchanges needed
to support the different QOS levels and the keep alive mechanism. This allows the user to concentrate on
publishing/subscribing and not the details of MQTT itself.

Examples of usage can be found in the examples directory.

The server client supports both normal and secure TCP connections and secure(wss) and non-secure(ws) websocket connections.
The browser client supports only secure(wss) and non-secure(ws) websocket connections.


Please read the changelog for details related to specific versions.

This version of the client supports the full MQTT Version 5 message set including the setting and reception of user 
properties and authentication using the authenticate message. Some aspects of the MQTT version 5 protocol are not yet fully 
implemented and will be added in future versions. If some particular currently unsupported functionality is needed please
raise an issue for it and this will be processed ahead of other functionality.

Omissions from the full MQTT Version 5 specification in this version are as follows :-

- Parameters received in the connect acknowledge message are not fully acted upon, e.g receive maximum and topic alias
maximum values for instance are not enforced.
- Subscription identifiers and shared subscriptions are not fully supported.
- Server redirection is not supported.
- Reason codes are processed only in support of the protocol itself, other than this although received reason codes are 
made available to the user the client will not necessarily take any action itself.
- Flow control and Request/Response functionality is not fully supported.

