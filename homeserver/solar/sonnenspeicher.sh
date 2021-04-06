#!/bin/sh

. ./_functions.sh

solar_load() {
	curl -sS -b "$COOKIE" "http://mein-sonnenspeicher.de/Device/CsvExport?dtype=2&service=0&typ=$1&period=$2"

}

solar_prepare() {
	awk -vFS=';' -vTYPE="$1" '
		NR==1 {
			for(i = 2; i < NF; i++) {
				h[i] = $i
				if(TYPE == "months")
					sub(/ \(kWh\)/, " Monat Wh", h[i])
				else if(TYPE == "days")
					sub(/ \(kWh\)/, " Tag Wh", h[i])
			}
			printf "{\"data\":["
		}
		NR>=3 {
			printf ","
		}
		NR>=2 {
			ds = ""
			split($1, d, "-")
			if(TYPE == "months")
				ds = sprintf("%04i-%02i", d[1], d[2])
			else if(TYPE == "days")
				ds = sprintf("%04i-%02i-%02i", d[1], d[2], d[3])
			printf "{\"dimension1\":\"%s\",\"dimension2\":\"%s\",\"value\":%i}\n", h[i], ds, $i
			for(i = 2; i < 9; i++) {
				sub(/,/, ".", $i)
				printf ",{\"dimension1\":\"%s\",\"dimension2\":\"%s\",\"value\":%i}\n", h[i], ds, $i * 1000
			}
		}
		END {
			printf "]}"
		}
	'
}

solar_auth() {
	curl -sS -X POST -o /dev/null -c "$COOKIE" \
		-F "UserName=$SONNENSPEICHER_USERNAME" \
		-F "Password=$SONNENSPEICHER_PASSWORD" \
		"http://mein-sonnenspeicher.de/Account/Login" ||
	exit
}

solar_summary_months() {
	solar_load jahresstatistik "$1" |
	solar_prepare months |
	solar_send "$DATASET_SONNENSPEICHER"
}

solar_summary_days() {
	RANGE=$(printf "%04i-%02i" "$1" "$2")
	solar_load monatsstatistik "$RANGE" |
	solar_prepare days |
	solar_send "$DATASET_SONNENSPEICHER"
}

solar_run
