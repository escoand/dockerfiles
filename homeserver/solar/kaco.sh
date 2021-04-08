#!/bin/sh

. ./_functions.sh

solar_load() {
	curl -sS "http://$KACO_HOST/$1"
}

solar_prepare() {
	# shellcheck disable=SC2016
	iconv |
	awk -vDATE="$1" -vRS='\r' -vFS='[/;]' '
		BEGIN {
			printf "["
		}
		NR==3 {
			for(i = 2; i <= NF; i++) {
				h[i] = $i
			}
		}
		NR>4 {
			printf ","
		}
		NR>=4&&NF==2 {
			printf "{\"field\":\"Erzeugung Jahr Wh\",\"value\":%f,\"date\":\"%04i-01-01T00:00:00\"}", $2, $1
		}
		NR>=4&&NF==3 {
			printf "{\"field\":\"Erzeugung Monat Wh\",\"value\":%f,\"date\":\"%04i-%02i-01T00:00:00\"}", $3, $2, $1
		}
		NR>=4&&NF==4 {
			printf "{\"field\":\"Erzeugung Tag Wh\",\"value\":%f,\"date\":\"%04i-%02i-%02iT00:00:00\"}", $4, $3, $2, $1
		}
		NR>=4&&NF>4 {
			for(i = 2; i <= NF; i++) {
				if(i > 2) {
					printf ","
				}
				printf "{\"field\":\"Erzeugung %s\",\"value\":%f,\"date\":\"%sT%s\"}", h[i], $i, DATE, $1
			}
		}
		END {
			printf "]"
		}
	'
}

solar_summary_years() {
	solar_load eternal.CSV |
	solar_prepare |
	solar_send
}

solar_summary_months() {
	solar_load "$1.CSV" |
	solar_prepare |
	solar_send
}

solar_summary_days() {
	DATE=$(printf "%04i%02i" "$1" "$2")
	solar_load "$DATE.CSV" |
	solar_prepare |
	solar_send
}

solar_current() {
	DATE=$(date +%Y%m%d)
	DATE2=$(date +%Y-%m-%d)
	solar_load "$DATE.CSV" |
	solar_prepare "$DATE2" |
	solar_send
}

solar_run
