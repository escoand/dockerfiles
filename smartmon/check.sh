#!/bin/sh

MQTT_HOST=${MQTT_HOST:-127.0.0.1}
MQTT_PORT=${MQTT_PORT:-1883}

while true; do
	for DEV in /dev/sd[0-9]*; do
		NAME=$(basename "$DEV")
		/usr/sbin/smartctl --info --all --json --nocheck standby "$DEV" |
		mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "smartctl/$HOSTNAME/$NAME" -s
	done

	# loop if LOOP_DELAY is a number: https://stackoverflow.com/a/808740
	[ "$LOOP_DELAY" -a "$LOOP_DELAY" -eq "$LOOP_DELAY" ] && sleep "$LOOP_DELAY" || break
done