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
	jq -c '{
		device: {
			identifiers: .serial_number,
			manufacturer: .model_family,
			model: .model_name,
			name: .model_name,
			sw_version: .firmware_version
		},
		"~": ("smartctl/" + env.HOSTNAME + "/" + env.NAME),
		json_attributes_topic: "~",
		json_attributes_template: "{ {% for _ in (test.ata_smart_attributes.table | selectattr(\"name\", \"in\", [\"ECC_Error_Rate\",\"CRC_Error_Count\",\"Uncorrectable_Error_Cnt\",\"Runtime_Bad_Block\",\"Erase_Fail_Count_Total\",\"Program_Fail_Cnt_Total\"]) | list) %}{% if not loop.first %},{% endif %}{{ \"\\\"\" ~ _.name ~ \"\\\":\" ~ _.raw.value }}{% endfor %} }",
		name: "Errors",
		state_topic: "~",
		unique_id: ("smartctl. " + .serial_number + ".errors"),
		value_template: "{{ value_json.ata_smart_error_log.summary.count }}"
	},
	{
		device: { identifiers: .serial_number },
		device_class: "temperature",
		name: "Temperature",
		state_topic: ("smartctl/" + env.HOSTNAME + "/" + env.NAME),
		unit_of_measurement: "°C",
		unique_id: ("smartctl. " + .serial_number + ".temperature"),
		value_template: "{{ value_json.temperature.current }}"
	}' |
	while read -r LINE; do
		mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "homeassistant/sensor/$RANDOM$RANDOM/config" -m "$LINE" -r
	done
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
