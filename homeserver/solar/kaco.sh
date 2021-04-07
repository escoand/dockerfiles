#!/bin/sh

. ./_functions.sh

solar_load() {
	curl -sS "http://$KACO_HOST/$1.CSV"
}

solar_prepare() {
	# shellcheck disable=SC2016
	tr '\r' '\n' |
	sed -n \
		-e '1i{"data":[' \
		-e '5,$s/^/,/' \
		-e '4,${s/^\(..\)\/\(..\)\/\(....\);\(.*\)$/{"field":"Erzeugung Tag Wh","value":\4,"date":"\3-\2-\1"}/p;}' \
		-e '4,${s/^\(..\)\/\(....\);\(.*\)$/{"field":"Erzeugung Monat Wh","value":\3,"date":"\2-\1"}/p;}' \
		-e '4,${s/^\(....\);\(.*\)$/{"field":"Erzeugung Jahr Wh","value":\2,"date":"\1"}/p;}' \
		-e '$i]}'
}

solar_summary_years() {
	solar_load eternal |
	solar_prepare |
	solar_send
}

solar_summary_months() {
	solar_load "$1" |
	solar_prepare |
	solar_send
}

solar_summary_days() {
	RANGE=$(printf "%04i%02i" "$1" "$2")
	solar_load "$RANGE" |
	solar_prepare |
	solar_send
}

solar_run
