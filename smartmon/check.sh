#!/bin/sh -x

MQTT_HOST=${MQTT_HOST:-127.0.0.1}
MQTT_PORT=${MQTT_PORT:-1883}
HOSTNAME=$(hostname)

# device info
ls /dev/sd[a-z] 2>/dev/null |
while read -r DEV; do
	export DEV HOSTNAME
	export NAME=$(basename "$DEV")
	/usr/sbin/smartctl --info --json "$DEV" |
	jq '{
		device: {
			identifiers: .serial_number,
			manufacturer: .model_family,
			model: .model_name,
			name: .model_name,
			sw_version: .firmware_version
		},
		name: ("Disk " + .serial_number),
		"~": ("smartctl/" + env.HOSTNAME + "/" + env.NAME),
		state_topic: "~",
		state_value_template: "{{ value_json.ata_smart_error_log.summary.count }}",
		current_temperature_topic: "~",
		current_temperature_template: "{{ value_json.temperature.current }}"
	}' |
	mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/$RANDOM$RANDOM/config" -s
done

# data
while true; do
	ls /dev/sd[a-z] 2>/dev/null |
	while read -r DEV; do
		NAME=$(basename "$DEV")
		/usr/sbin/smartctl --all --json --nocheck standby "$DEV" |
		mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "smartctl/$HOSTNAME/$NAME" -s
	done

	# loop if LOOP_DELAY is a number: https://stackoverflow.com/a/808740
	if [ "$LOOP_DELAY" ] && [ "$LOOP_DELAY" -eq "$LOOP_DELAY" ]; then
		sleep "$LOOP_DELAY"
	else
		break
	fi
done
