#!/bin/sh

XSL=/usr/local/bin/workout2svg.xslt
CLASSPATH=$(ls /usr/local/java/*.jar 2>/dev/null | tr '\n' ';' | sed 's/;$//')
TEMP=$(mktemp)

export CLASSPATH

find "$@" -type f \( -name '*.gpx' -o -name '*.tcx' \) |
while read -r FILE; do
	DIR=$(dirname "$FILE")
	EXT=${FILE##*.}
	BASE=$(tr -d '\n\r' < "$FILE" |
		sed 's#\(</[^>]*>\)#&\n#g' |
		sed -n '
			/<metadata>/,/<\/metadata>/ { s#.*<time>\(.*\)T\(..\):\(..\):\(..\).*#\1_\2-\3-\4#p; /^20..-..-/q; }
			s#.*<Id>\(.*\)T\(..\):\(..\):\(..\).*#\1_\2-\3-\4#p; /^20..-..-/q
		'
	)
	NEW="$DIR/$BASE.$EXT"
	PNG="$DIR/$BASE.png"

	# rename
	if [ -n "$BASE" ] && [ "$FILE" != "$NEW" ]; then
		echo "$FILE -> $NEW"
		if [ -n "$FORCE" ]; then
			mv -f "$FILE" "$NEW"
		else
			mv -n "$FILE" "$NEW"
		fi
		rm -f "$PNG"
	fi

	# graph
	if [ -n "$FORCE" ] || [ ! -f "$PNG" ]; then
		echo "$NEW -> $PNG"
		java net.sf.saxon.Transform -xsl:"$XSL" -s:"$NEW" -o:"$TEMP" "mapboxStyle=$MAPBOX_STYLE" "mapboxToken=$MAPBOX_TOKEN" &&
		sed -n 's|.*href="\([^"]*\)".*|\1|gp' "$TEMP" |
		sort -u |
		while read -r URL; do
			DATA=$(wget -nv -O- "$URL" | base64 -w0)
			sed -i -f - "$TEMP" <<EOF &&
s|$URL|data:image/png;base64,$DATA|g
EOF
			rsvg-convert -o "$PNG" "$TEMP"
			rm -f "$TEMP"
		done
		chmod 666 "$PNG"
	fi

	# command after
	[ "$CMD_AFTER" ] && eval "$CMD_AFTER"

done