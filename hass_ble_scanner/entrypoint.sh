#!/bin/sh

[ "$DEBUG" ] && set -x

SCAN_TIME=${SCAN_TIME:-10}
MQTT_HOST=${MQTT_HOST:-localhost}
MQTT_PORT=${MQTT_PORT:-1883}
TOPIC_PRE=${TOPIC_PRE-location/}
TOPIC_POST=${TOPIC_POST-}
PAYLOAD=${PAYLOAD-home}
WAIT_TIME=${WAIT_TIME:-90}

# main loop
while true; do
	hciconfig hci0 reset

	# scan
	printf "%s scanning for %i seconds\n" "$(date +%Y-%m-%d\ %H:%M:%S)" "$SCAN_TIME"
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
			-t "$TOPIC_PRE{}$TOPIC_POST" \
			-m "$PAYLOAD" \
			"$@"

	# sleep
	printf "%s sleeping for %i seconds\n" "$(date +%Y-%m-%d\ %H:%M:%S)" "$WAIT_TIME"
	sleep "$WAIT_TIME"

done
