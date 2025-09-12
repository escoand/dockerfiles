#!/bin/bash

set -eu

NAME=default
PORT=1:65535
PROTOCOL=tcp
FAMILY=ipv4
CHAIN=INPUT_direct
BLOCKTYPE="REJECT --reject-with icmp-port-unreachable"

urldecode() {
    : "${*//+/ }"
    echo -e "${_//%/\\x}"
}

result() {
    code=$1
    shift
    printf 'HTTP/1.1 %i %s\r\nConnection: close\r\n\r\n%s' "$code" "$*" "$*"
    exit
}

trap 'result 500 FAIL' ERR

while read -r method uri _; do
    ip=$(urldecode "${uri#/}")
    case "$method" in
    START)
        firewall-cmd --direct --add-chain $FAMILY filter f2b-$NAME
        firewall-cmd --direct --add-rule $FAMILY filter f2b-$NAME 1000 -j RETURN
        firewall-cmd --direct --add-rule $FAMILY filter $CHAIN 0 -m state --state NEW -p $PROTOCOL -m multiport --dports $PORT -j f2b-$NAME
        ;;
    STOP)
        firewall-cmd --direct --remove-rule $FAMILY filter $CHAIN 0 -m state --state NEW -p $PROTOCOL -m multiport --dports $PORT -j f2b-$NAME
        firewall-cmd --direct --remove-rules $FAMILY filter f2b-$NAME
        firewall-cmd --direct --remove-chain $FAMILY filter f2b-$NAME
        ;;
    CHECK)
        firewall-cmd --direct --get-chains $FAMILY filter | sed -e 's, ,\n,g' | grep -q "f2b-$NAME$"
        ;;
    BAN)
        # shellcheck disable=SC2086
        firewall-cmd --direct --add-rule $FAMILY filter f2b-$NAME 0 -s "$ip" -j $BLOCKTYPE
        ;;
    UNBAN)
        # shellcheck disable=SC2086
        firewall-cmd --direct --remove-rule $FAMILY filter f2b-$NAME 0 -s "$ip" -j $BLOCKTYPE
        ;;
    *)
        result 405 Method Not Allowed
        ;;
    esac
done

result 200 OK
