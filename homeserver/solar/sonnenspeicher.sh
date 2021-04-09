#!/bin/sh

. ./_functions.sh

solar_auth() {
	solar_log auth
	curl -isS -X POST -c "$COOKIE" \
		-F "UserName=$SONNENSPEICHER_USER" \
		-F "Password=$SONNENSPEICHER_PASSWORD" \
		"http://mein-sonnenspeicher.de/Account/Login" |
	sed -n 's/^HTTP\/[^ ]* //p'
}

solar_load() {
	curl -sS -b "$COOKIE" "http://mein-sonnenspeicher.de/Device/CsvExport?dtype=2&service=0&typ=$1&period=$2"
}

solar_prepare() {
	awk -vFS=';' -vTYPE="$1" '
		BEGIN {
			printf "["
		}
		NR==1 {
			for(i = 2; i <= NF; i++) {
				h[i] = $i
				if(TYPE == "months") {
					sub(/ \(kWh\)$/, " Monat (kWh)", h[i])
					sub(/ %$/, " Monat Prz", h[i])
				} else if(TYPE == "days") {
					sub(/ \(kWh\)$/, " Tag (kWh)", h[i])
					sub(/ %$/, " Tag Prz", h[i])
				}
			}
		}
		NR>=2 {
			ds = ""
			split($1, d, "-")
			if(TYPE == "months") {
				ds = sprintf("%04i-%02i-01T00:00:00", d[1], d[2])
			} else if(TYPE == "days") {
				ds = sprintf("%04i-%02i-%02iT00:00:00", d[1], d[2], d[3])
			} else if(TYPE == "minutes") {
				split(d[3], t, ":")
				sub(/ .*/, "", d[3])
				sub(/.* /, "", t[1])
				ds = sprintf("%04i-%02i-%02iT%02i:%02i:00", d[1], d[2], d[3], t[1], t[2])
			}
			for(i = 2; i < NF; i++) {
				if(NR > 2 || i > 2) {
					printf ","
				}
				sub(/,/, ".", $i)
				printf "{\"field\":\"%s\",\"value\":%f,\"date\":\"%s\"}\n", h[i], $i, ds
			}
		}
		END {
			printf "]"
		}
	'
}

solar_summary_months() {
	solar_load jahresstatistik "$1" |
	solar_prepare months |
	solar_send
}

solar_summary_days() {
	DATE=$(printf "%04i-%02i" "$1" "$2")
	solar_load monatsstatistik "$DATE" |
	solar_prepare days |
	solar_send
}

solar_day() {
	DATE=$(printf "%04i-%02i-%02i" "$1" "$2" "$3")
	solar_load tagesstatistik "$DATE" |
	solar_prepare minutes |
	solar_send
}

solar_run
