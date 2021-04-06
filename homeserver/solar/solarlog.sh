#!/bin/sh

. ./_functions.sh

solar_auth() {
	curl -sS -X POST -o /dev/null -c "$COOKIE" \
		--data-urlencode "u=$SOLARLOG_USER" \
		--data-urlencode "p=$SOLARLOG_PASSWORD" \
		"$URL_SOLARLOG/login"
}

solar_load() {
	TOKEN=$(sed -n 's/.*\tSolarLog\t//p' "$COOKIE")
	curl -sS -X POST -b "$COOKIE" -d "token=$TOKEN;$1" "$URL_SOLARLOG/getjp"
}

solar_summary() {
	# years
	solar_log years
	solar_load '{"878":null}' |
	jq '{"data":[
			."878"[] |
				.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y")) |
				{"dimension1":"Ertrag Jahr Wh","dimension2":.[99],"value":.[1]}
		]}' |
	solar_send "$DATASET_SOLARLOG"

	# months
	solar_log months
	solar_load '{"877":null}' |
	jq '{"data":[
			."877"[] |
				.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y-%m")) |
				{"dimension1":"Ertrag Monat Wh","dimension2":.[99],"value":.[1]}
		]}' |
	solar_send "$DATASET_SOLARLOG"
}

solar_current() {
	solar_log current
	solar_load '{"801":{"170":null}}' |
	jq '."801"."170" |
		.date=(."100" | strptime("%d.%m.%y %H:%M:%S") | strflocaltime("%Y-%m-%dT%H:%I:%S%z")) |
		{"data":[
			{"dimension1":"Ertrag W","dimension2":.date,"value":."101"},
			{"dimension1":"Ertrag V","dimension2":.date,"value":."103"},
			{"dimension1":"Verbrauch W","dimension2":.date,"value":."110"}
		]}' |
	solar_send "$DATASET_CURRENT"
}

solar_run
