#!/bin/sh

[ "$DEBUG" ] && set -x

SCAN_TIME=${SCAN_TIME:-10}
MQTT_HOST=${MQTT_HOST:-localhost}
MQTT_PORT=${MQTT_PORT:-1883}
TOPIC=${TOPIC:-location/docker}
WAIT_TIME=${WAIT_TIME:-110}

# main loop
while true; do

	# scan
	(
		hcitool lescan &
		sleep "$SCAN_TIME"
		kill -2 $!
	) |

	# optimize
	sed '
		/^LE Scan ...$/d
		/ (unknown)$/d
		s/^/BLE_/
		s/ .*$//
	' |

	# publish
	xargs -ti \
		mosquitto_pub \
			-h "$MQTT_HOST" \
			-p "$MQTT_PORT" \
			-V mqttv311 \
			-t "$TOPIC" \
			-m "{}" \
			"$@"

	# sleep
	sleep "$WAIT_TIME"

done
