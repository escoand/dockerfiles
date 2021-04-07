#!/bin/sh

. ./_functions.sh

solar_auth() {
	curl -sS -X POST -o /dev/null -c "$COOKIE" \
		--data-urlencode "u=$SOLARLOG_USER" \
		--data-urlencode "p=$SOLARLOG_PASSWORD" \
		"http://$SOLARLOG_HOST/login"
}

solar_load() {
	TOKEN=$(sed -n 's/.*\tSolarLog\t//p' "$COOKIE")
	curl -sS -X POST -b "$COOKIE" -d "token=$TOKEN;$1" "http://$SOLARLOG_HOST/getjp"
}

solar_prepare() {
	jq '{"data":[
		try ."801"."170" |
			.date=(."100" | strptime("%d.%m.%y %H:%M:%S") | todate) |
			{"dimension1":"Ertrag W","dimension2":.date,"value":."101"},
			{"dimension1":"Ertrag V","dimension2":.date,"value":."103"},
			{"dimension1":"Verbrauch W","dimension2":.date,"value":."110"},
		try ."877"[] |
			.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y-%m")) |
			{"dimension1":"Ertrag Monat Wh","dimension2":.[99],"value":.[1]},
		try ."878"[] |
			.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y")) |
			{"dimension1":"Ertrag Jahr Wh","dimension2":.[99],"value":.[1]}
	]}'
}

solar_summary() {
	# years
	solar_log years
	solar_load '{"878":null}' |
	solar_prepare |
	solar_send

	# months
	solar_log months
	solar_load '{"877":null}' |
	solar_prepare |
	solar_send
}

solar_current() {
	solar_log current
	solar_load '{"801":{"170":null}}' |
	solar_prepare |
	solar_send
}

solar_run
