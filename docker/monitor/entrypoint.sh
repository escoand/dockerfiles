#!/bin/sh
# shellcheck disable=SC2016

set -e

WAIT=60

# main loop
curl -fNsS --unix-socket /var/run/docker.sock http://localhost/events |
    jq -r --unbuffered '
        select(
            (.status=="health_status" and .HealthStatus=="healthy") | not
        ) |
        [ (.time | localtime | strftime("%Y-%m-%d %H:%M:%S")), .Type, .Actor.Attributes.name // .from, .HealthStatus // .Action // .status ] |
        join(" ")
    ' |

    # wait for input
    while read -r LINE; do
        END=$(($(date +%s) + WAIT))
        REMAINING=$WAIT
        {
            echo "Subject: Docker events"
            echo
            echo "$LINE"
            while read -r -t $REMAINING LINE; do
                echo "$LINE"
                REMAINING=$((END - $(date +%s)))
                [ $REMAINING -lt 0 ] && break
            done
        } |

            # log
            tee /dev/stderr |

            # send mail
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
    done
