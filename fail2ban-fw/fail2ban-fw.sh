#!/bin/bash
# shellcheck disable=SC2015

set -eu

FAMILY=ipv4
CHAIN=INPUT_direct
NAME=fail2ban
BLOCKTYPE=DROP
# internal
skip=FALSE

start() {
    firewall-cmd --direct --add-chain $FAMILY filter $NAME >&2 &&
        firewall-cmd --direct --add-rule $FAMILY filter $NAME 1000 -j RETURN >&2 &&
        firewall-cmd --direct --add-rule $FAMILY filter $CHAIN 0 -j $NAME >&2
}

stop() {
    firewall-cmd --direct --remove-rule $FAMILY filter $CHAIN 0 -j $NAME >&2 &&
        firewall-cmd --direct --remove-rules $FAMILY filter $NAME >&2 &&
        firewall-cmd --direct --remove-chain $FAMILY filter $NAME >&2
}

check() {
    firewall-cmd --direct --query-chain $FAMILY filter $NAME >&2
}

ban() {
    # shellcheck disable=SC2086
    firewall-cmd --direct --add-rule $FAMILY filter $NAME 0 -s "$1" -j $BLOCKTYPE >&2
}

unban() {
    # shellcheck disable=SC2086
    firewall-cmd --direct --remove-rule $FAMILY filter $NAME 0 -s "$1" -j $BLOCKTYPE >&2
}

urldecode() {
    : "${*//+/ }"
    echo -e "${_//%/\\x}"
}

result() {
    code=$1
    shift
    echo "  > result $code: $*" >&2
    printf 'HTTP/1.1 %i %s\r\nConnection: close\r\n\r\n' "$code" "$*"
}

{
    while read -r method uri _; do
        ip=$(urldecode "${uri#/}")
        [ "$skip" != TRUE ] && echo "$method $ip" >&2
        # end of headers
        if [ -z "$method" ] || [ "$method" = $'\r' ]; then
            break
        # skip headers
        elif [ "$skip" = TRUE ]; then
            continue
        # start
        elif [ "$method" = START ] && check; then
            result 200 OK
        elif [ "$method" = START ]; then
            start && result 200 OK || result 500 FAIL
        # stop
        elif [ "$method" = STOP ] && check; then
            stop && result 200 OK || result 500 FAIL
        elif [ "$method" = STOP ]; then
            result 200 OK
        # check
        elif [ "$method" = CHECK ]; then
            check && result 200 OK || result 500 FAIL
        # ban
        elif [ "$method" = BAN ]; then
            ban "$ip" && result 200 OK || result 500 FAIL
        # unban
        elif [ "$method" = UNBAN ]; then
            unban "$ip" && result 200 OK || result 500 FAIL
        # invalid
        else
            result 405 Method Not Allowed
        fi
        skip=TRUE
    done 2>&1 1>&3 | logger -t fail2ban-fw
} 3>&1
