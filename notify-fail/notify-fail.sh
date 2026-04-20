#!/bin/sh
# Required: ~/.config/notify-fail.env with MATRIX_HOST, MATRIX_ACCESS_TOKEN, MATRIX_ROOM_ID

set -e

UNIT="$1"
UUID=$(uuidgen)
BODY=$(
    printf "Service %s failed:\n" "$UNIT"
    journalctl -u "${UNIT}.service" --no-pager -o cat -n 10 2>/dev/null || true
)

jq -cn --arg b "$BODY" '{msgtype:"m.text",body:$b}' |
    curl -fsS -XPUT \
        --data-binary @- \
        -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" \
        "$MATRIX_HOST/_matrix/client/v3/rooms/$MATRIX_ROOM_ID/send/m.room.message/$UUID"
