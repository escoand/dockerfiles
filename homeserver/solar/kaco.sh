#!/bin/sh

. ./_functions.sh

solar_load() {
	curl -sS "$URL_KACO/$1.CSV"
}

solar_prepare() {
	# shellcheck disable=SC2016
	tr '\r' '\n' |
	sed -n \
		-e '1i{"data":[' \
		-e '5,$s/^/,/' \
		-e '4,${s/^\(..\)\/\(..\)\/\(....\);\(.*\)$/{"dimension1":"Ertrag Tag Wh","dimension2":"\3-\2-\1","value":\4}/p;}' \
		-e '4,${s/^\(..\)\/\(....\);\(.*\)$/{"dimension1":"Ertrag Monat Wh","dimension2":"\2-\1","value":\3}/p;}' \
		-e '4,${s/^\(....\);\(.*\)$/{"dimension1":"Ertrag Jahr Wh","dimension2":"\1","value":\2}/p;}' \
		-e '$i]}'
}

solar_summary_years() {
	solar_load eternal |
	solar_prepare |
	solar_send "$DATASET_KACO"
}

solar_summary_months() {
	solar_load "$1" |
	solar_prepare |
	solar_send "$DATASET_KACO"
}

solar_summary_days() {
	RANGE=$(printf "%04i%02i" "$1" "$2")
	solar_load "$RANGE" |
	solar_prepare |
	solar_send "$DATASET_KACO"
}

solar_run
