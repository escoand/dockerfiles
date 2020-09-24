#!/bin/sh

MQTT_HOST=${MQTT_HOST:-127.0.0.1}
MQTT_PORT=${MQTT_PORT:-1883}
HOSTNAME=$(hostname)

while true; do
	ls /dev/sd[0-9]* 2>/dev/null |
	while read -r DEV; do
		NAME=$(basename "$DEV")
		/usr/sbin/smartctl --info --all --json --nocheck standby "$DEV" |
		mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "smartctl/$HOSTNAME/$NAME" -s
	done

	# loop if LOOP_DELAY is a number: https://stackoverflow.com/a/808740
	if [ "$LOOP_DELAY" ] && [ "$LOOP_DELAY" -eq "$LOOP_DELAY" ]; then
		sleep "$LOOP_DELAY"
	else
		break
	fi
done
