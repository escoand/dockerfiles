#!/bin/sh

START=

# summary
summary() {
	curl -sS "$URL_KACO/$1.CSV" |
	tr '\r' '\n' |
	sed -n \
		-e '1i{"data":[' \
		-e '5,$i,' \
		-e '4,${s/^\(..\)\/\(..\)\/\(....\);\(.*\)$/{"dimension1":"Ertrag Tag Wh","dimension2":"\3-\2-\1","value":\4}/p;}' \
		-e '4,${s/^\(..\)\/\(....\);\(.*\)$/{"dimension1":"Ertrag Monat Wh","dimension2":"\2-\1","value":\3}/p;}' \
		-e '4,${s/^\(....\);\(.*\)$/{"dimension1":"Ertrag Jahr Wh","dimension2":"\1","value":\2}/p;}' \
		-e '$i]}' |
	curl -sS -X POST -o /dev/null \
		-u "$AUTH_NEXTCLOUD" \
		-H "Content-type: application/json" \
		--data-binary @- \
		"https://$DOMAIN_NEXTCLOUD/index.php/apps/analytics/api/2.0/adddata/$DATASET_KACO"
}

# summary
if [ "$START" ]; then
	summary eternal

	_YEAR=$(date +%Y)
	YEAR=$START
	while [ $YEAR -le $_YEAR ]; do
		summary "$YEAR"

		MONTH=1
		while [ $MONTH -le 12 ]; do
			summary "$(printf "%04i%02i" $YEAR $MONTH)"
			MONTH=$((MONTH+1))
		done

		YEAR=$((YEAR+1))
	done
fi
summary "$(date +%Y%m)"

# current
# TODO
