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
        LASTING=$WAIT
        {
            echo "$LINE"
            while read -r -t $LASTING LINE; do
                echo "$LINE"
                LASTING=$((END - $(date +%s)))
                [ $LASTING -lt 0 ] && break
            done
        } |

            # debug
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
