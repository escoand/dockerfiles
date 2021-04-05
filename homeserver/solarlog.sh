#!/bin/sh

# summary
summary() {
	cat |
	curl -sS -X POST -o /dev/null \
		-u "$AUTH_NEXTCLOUD" \
		-H "Content-type: application/json" \
		--data-binary @- \
		"https://$DOMAIN_NEXTCLOUD/index.php/apps/analytics/api/2.0/adddata/$DATASET_SOLARLOG"
}

# summary years
summary_years() {
	curl -sS -X POST \
		-d '{"878":null}' \
		 "$URL_SOLARLOG" |
	jq '{"data":[
			."878"[] |
				.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y")) |
				{"dimension1":"Ertrag Jahr Wh","dimension2":.[99],"value":.[1]}
		]}' |
	summary
}

# summary months
summary_months() {
	curl -sS -X POST \
		-d '{"877":null}' \
		 "$URL_SOLARLOG" |
	jq '{"data":[
			."877"[] |
				.[99]=(.[0] | strptime("%d.%m.%y") | strflocaltime("%Y-%m")) |
				{"dimension1":"Ertrag Monat Wh","dimension2":.[99],"value":.[1]}
		]}' |
	summary
}

# current
current() {
	curl -sS -X POST \
		-d '{"801":{"170":null}}' \
		 "$URL_SOLARLOG" |
	jq '."801"."170" |
		.date=(."100" | strptime("%d.%m.%y %H:%M:%S") | strflocaltime("%Y-%m-%dT%H:%I:%S%z")) |
		{"data":[
			{"dimension2":.date,"value":."101","dimension1":"Ertrag W"},
			{"dimension2":.date,"value":."103","dimension1":"Ertrag V"},
			{"dimension2":.date,"value":."110","dimension1":"Verbrauch W"}
		]}' |
	curl -sS -X POST -o /dev/null \
		-u "$AUTH_NEXTCLOUD" \
		-H "Content-type: application/json" \
		--data-binary @- \
		"https://$DOMAIN_NEXTCLOUD/index.php/apps/analytics/api/2.0/adddata/$DATASET_CURRENT"
}



# read
summary_years
summary_months
current
