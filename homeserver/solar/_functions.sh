#!/bin/sh

SCRIPT=$(basename "$0" .sh)
COOKIE=$(mktemp)

solar_log() {
	printf '%-15s %-8s ' "$SCRIPT" "$1"
}

solar_prepare() {
	cat
}

solar_send() {
	# shellcheck disable=SC1003
	curl -sS -X POST \
		-u "$AUTH_NEXTCLOUD" \
		-H "Content-type: application/json" \
		--data-binary @- \
		"https://$DOMAIN_NEXTCLOUD/index.php/apps/analytics/api/2.0/adddata/$1" |
	sed -e '$a\' |
	grep -v '^$'
}

solar_auth() {
	true
}

solar_summary_years() {
	echo not_defined
}

solar_summary_months() {
	echo not_defined
}

solar_summary_days() {
	echo not_defined
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
	echo not_defined
}

solar_clean() {
	rm -f "$COOKIE"
}

solar_run() {
	solar_auth
	[ -n "$START_YEAR" ] && solar_summary
	solar_log current
	solar_current
	solar_clean
}