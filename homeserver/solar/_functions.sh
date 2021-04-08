#!/bin/sh

COOKIE=$(mktemp)
SCRIPT=$(basename "$0" .sh)
TZOFFSET=$(date +'"%z"' | jq -r '(.[0:3] | tonumber) * 60 *60 + (.[3:5] | tonumber) * 60')

solar_log() {
	printf '%-15s %-8s ' "$SCRIPT" "$1"
}

solar_auth() {
	true
}

solar_prepare() {
	cat
}

solar_send() {
	# shellcheck disable=SC1003
	jq -r --arg type "$SCRIPT" '
		.[] |
			.name=(.field | ascii_downcase | gsub("[^a-z,]+"; "_") | sub("_+$"; "")) |
			.tstamp=(.date | strptime("%Y-%m-%dT%H:%M:%S") | mktime) |
			(if .tstamp < now then
				(if .tag then .tag else $type end) + " " + .name + "=" + (.value | tostring) + " " + (.tstamp | tostring)
			else empty end)
	' |
	if [ -z "$DEBUG" ]; then
		curl -isS -XPOST \
			-H "Authorization: Token $INFLUXDB_TOKEN" \
			--data-binary @- \
			"http://$INFLUXDB_HOST/api/v2/write?org=$INFLUXDB_ORG&bucket=$INFLUXDB_BUCKET&precision=s" |
		sed -n 's/^HTTP\/[^ ]* //p'
	else
		echo
		cat >&2
		echo
	fi
}

solar_summary_years() {
	echo no_data
}

solar_summary_months() {
	echo no_data
}

solar_summary_days() {
	echo no_data
}

solar_summary() {
	THIS_YEAR=$(date +%Y)
	YEAR=$START_YEAR
	solar_log years
	solar_summary_years
	while [ "$YEAR" -le "$THIS_YEAR" ]; do
		solar_log "$YEAR"
		solar_summary_months "$YEAR"
		MONTH=1
		while [ "$MONTH" -le 12 ]; do
			solar_log "$YEAR-$MONTH"
			solar_summary_days "$YEAR" "$MONTH"
			MONTH=$((MONTH+1))
		done
		YEAR=$((YEAR+1))
	done
}

solar_current() {
	YEAR=$(date +%Y)
	MONTH=$(date +%m)
	solar_summary_days "$YEAR" "$MONTH"
}

solar_clean() {
	rm -f "$COOKIE"
}

solar_run() {
	# check db
	if [ -z "$DEBUG" ]; then
		solar_log db
		while ! curl -s -o /dev/null "http://$INFLUXDB_HOST/health"; do
			printf .
			sleep 5
		done
		echo ready
	fi

	# do it
	if ! solar_auth; then
		solar_log login
		echo failed
		return
	fi
	[ -n "$START_YEAR" ] && solar_summary
	solar_log current
	solar_current
	solar_clean
}
