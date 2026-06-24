#!/bin/bash

set -eu

WAIT=60
MATRIX_ACCESS_TOKEN=$(
    jq -n '{"type":"m.login.password","user":env.MATRIX_USER,"password":env.MATRIX_PASSWORD}' |
        curl -fsS \
            --data-binary @- \
            "${MATRIX_HOST?}/_matrix/client/r0/login" |
        jq -r '.access_token'
)
: "${MATRIX_ROOM_ID?}"
TMP=$(mktemp)

send_mail() {
    {
        echo "Subject: Docker events"
        echo
        cat
    } |
        msmtp \
            --tls=on \
            --tls-starttls=off \
            --auth=plain \
            --host="${MAIL_HOST?}" \
            --port="${MAIL_PORT:-465}" \
            --user="${MAIL_USER?}" \
            --passwordeval='cat /run/secrets/MAIL_PASSWORD' \
            --from="${MAIL_FROM:-MAIL_TO}" \
            "${MAIL_TO?}"
}

send_matrix() {
    UUID=$(uuidgen)
    jq -cRs '{msgtype:"m.text",body:.}' >"$TMP"
    curl -fsS -XPUT \
        --data-binary "@$TMP" \
        -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" \
        "$MATRIX_HOST/_matrix/client/v3/rooms/$MATRIX_ROOM_ID/send/m.room.message/$UUID"
}

# watch events
while true; do
    curl -fNsS \
        --unix-socket /var/run/docker.sock \
        http://localhost/events
done |

    # filter events
    jq -r --unbuffered '
        select(
            (.status=="health_status" and .HealthStatus=="healthy") | not
        ) |
        [ (.id // "-"), (.time | localtime | strftime("%Y-%m-%d %H:%M:%S")), .Type, .Actor.Attributes.name // .from, .HealthStatus // .Action // .status ] |
        join(" ")
    ' |

    # get logs
    while read -r _ TIME TYPE NAME STATUS; do
        echo "$TIME $TYPE $NAME $STATUS"
        [[ $TYPE = container && $STATUS = @(stopped|die) ]] &&
            journalctl -n 10 -o short-iso "CONTAINER_NAME=$NAME" 2>&1
    done |

    # stderr
    tee /dev/stderr |

    # send blocked
    while read -r LINE; do
        END=$(($(date +%s) + WAIT))
        REMAINING=$WAIT
        {
            echo "$LINE"
            # shellcheck disable=SC3045
            while read -r -t $REMAINING LINE; do
                echo "$LINE"
                REMAINING=$((END - $(date +%s)))
                [ $REMAINING -lt 0 ] && break
            done
        } |

            # send
            send_matrix
    done
