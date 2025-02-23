#!/bin/bash
#
# Test client
#
mqttx conn \
    -h test.mosquitto.org \
    -p 8081 \
    --protocol wss \
    --client-id "test-b" \
    --will-topic "mqtt5_client/test/disconnect_with_will" \
    --will-message "TEST DISCONNECTED (CLI)" \
    --will-qos 0
