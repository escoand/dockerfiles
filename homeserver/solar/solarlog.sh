#!/bin/sh

. ./_functions.sh

# {
#   "613": "dd.mm.yy",
#   "614": "HH:MM:ss",
#   "615": "HH:MM",
#   "701": "09.04.21 12:13:13", # current time
#   "771": [[
#     "1617408000", # timestamp
#     "2855",       # Erzeugung Wh
#     "3195"        # Verbrauch Wh
#   ]],
#	"776": {
#		"4": [ # diff to current day
#			[ "00:35:00", [
#					[0,0],
#					[18,9], # Erzeugung W, Wh
#					[20,3]  # Verbrauch W, Wh
#			]]
#		]
#	},
#	"777": {
#		"4": [ # diff to current day
#			[ "05.04.21", [
#					0,
#					392, # Erzeugung Wh
#					3444 # Verbrauch Wh
#			]]
#		]
#	},
#	"778": {
#		"4": [ # diff to current day
#			[ "05.04.21", [
#					254, # Eigenverbrauch Wh
#					0,
#					0,
#					0
#			]]
#		]
#	},
#   "780": 991, # Erzeugung W
#   "781": 500, # Verbrauch W
#}


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
	TZ=UTC jq --arg host "$SOLARLOG_HOST" '[
		(."776" | if . then . else empty end | to_entries | .[] | .key as $diff | .value[] |
			.[99]=(now - ($diff | tonumber) * 24 * 60 * 60 | strftime("%Y-%m-%dT")) |
			{
				"date": (.[99] + .[0]),
				"field": "Erzeugung W",
				"value": .[1][1][0]
			},
			{
				"date": (.[99] + .[0]),
				"field": "Erzeugung Wh",
				"value": .[1][1][1]
			},
			{
				"date": (.[99] + .[0]),
				"field": "Verbrauch W",
				"value": .[1][2][0]
			},
			{
				"date": (.[99] + .[0]),
				"field": "Verbrauch Wh",
				"value": .[1][2][1]
			}
		),
		(."801"."170" | if . then . else empty end |
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
		(."877" | if . then .[] else empty end |
			.[99]=(.[0] | strptime("%d.%m.%y") | strftime("%Y-%m-%dT%H:%M:%S")) |
			{
				"field": "Erzeugung Monat Wh",
				"value": .[1],
				"date": .[99],
				"tag": ("solarlog,host=" + $host)
			}
		),
		(."878" | if . then .[] else empty end |
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

solar_day() {
	solar_load "{\"776\":{\"$4\":null}}" |
	solar_prepare |
	solar_localtime2utc |
	solar_send
}

solar_current() {
	solar_log current
	solar_load '{"801":{"170":null}}' |
	solar_prepare |
	solar_localtime2utc |
	solar_send
}

solar_run
