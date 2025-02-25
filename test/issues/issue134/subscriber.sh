#!/bin/bash
#
# Creates an MQTT 5 client that subscribes to the will topic
#
mqttx sub \
    -h test.mosquitto.org \
    -p 8081 \
    --protocol wss \
    --client-id "mqtt5-client" \
    --qos 2 \
    --topic "mqtt5_client/test/disconnect_with_will"
