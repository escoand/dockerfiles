#!/bin/sh

. ./_functions.sh

solar_auth() {
	solar_log auth
	curl -sS -X POST -c "$COOKIE" \
		--data-urlencode "u=$SOLARLOG_USER" \
		--data-urlencode "p=$SOLARLOG_PASSWORD" \
		"http://$SOLARLOG_HOST/login" |
	tail -n1
}

solar_load() {
	TOKEN=$(sed -n 's/.*\tSolarLog\t//p' "$COOKIE")
	curl -sS -X POST -b "$COOKIE" -d "token=$TOKEN;$1" "http://$SOLARLOG_HOST/getjp"
}

solar_prepare() {
	jq --arg host "$SOLARLOG_HOST" '[
		(try ."801"."170" |
			.date=(."100" | strptime("%d.%m.%y %H:%M:%S") | strftime("%Y-%m-%dT%H:%M:%S")) |
			{
				"field": "Erzeugung W",
				"value": ."101",
				"date": .date,
				"tag": ("solarlog,host=" + $host)
			},
			{
				"field": "Erzeugung V",
				"value": ."103",
				"date": .date,
				"tag": ("solarlog,host=" + $host)
			},
			{
				"field": "Verbrauch W",
				"value": ."110",
				"date": .date,
				"tag": ("solarlog,host=" + $host)
			}
		),
		(try ."877"[] |
			.[99]=(.[0] | strptime("%d.%m.%y") | strftime("%Y-%m-%dT%H:%M:%S")) |
			{
				"field": "Erzeugung Monat Wh",
				"value": .[1],
				"date": .[99],
				"tag": ("solarlog,host=" + $host)
			}
		),
		(try ."878"[] |
			.[99]=(.[0] | strptime("%d.%m.%y") | strftime("%Y-%m-%dT%H:%M:%S")) |
			{
				"field": "Erzeugung Jahr Wh",
				"value": .[1],
				"date": .[99],
				"tag": ("solarlog,host=" + $host)
			}
		)
	]'
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
