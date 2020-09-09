#!/bin/sh

XSL=/app/workout2svg.xslt
FILE=$1
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
SVG="$DIR/$BASE.svg"

# rename
if [ -n "$BASE" ] && [ "$FILE" != "$NEW" ]; then
	echo "$FILE -> $NEW"
	if [ -n "$FORCE" ]; then
		mv -f "$FILE" "$NEW"
	else
		mv -n "$FILE" "$NEW"
	fi
	rm -f "$SVG"
fi

# graph
if [ -n "$FORCE" ] || [ ! -f "$SVG" ]; then
	echo "$NEW -> $SVG"
	java -cp /app/*.jar net.sf.saxon.Transform -xsl:"$XSL" -s:"$NEW" -o:"$SVG"
	chmod 666 "$SVG"
fi
