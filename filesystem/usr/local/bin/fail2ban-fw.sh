#!/bin/bash
# shellcheck disable=SC2015

set -eu

FAMILY=ipv4
CHAIN=INPUT_direct
NAME=fail2ban
BLOCKTYPE=DROP

if command -v ipset >/dev/null; then
    CMD=ipset
elif command -v nft >/dev/null; then
    CMD=nft
else
    echo unknown firewall >&2
    exit 1
fi

start() {
    if [ "$CMD" = ipset ]; then
        ipset -exist -quiet create $NAME hash:ip >&2 &&
            firewall-cmd --direct --add-rule $FAMILY filter $CHAIN 0 -m set --match-set $NAME src -j $BLOCKTYPE
    elif [ "$CMD" = nft ]; then
        nft add table inet $NAME &&
            nft add set inet $NAME $NAME "{ type ipv4_addr; flags dynamic; }" &&
            nft add chain inet $NAME input "{ type filter hook input priority 0; }" &&
            nft add rule inet $NAME input ip saddr @$NAME drop
    fi >&2
}

stop() {
    if [ "$CMD" = ipset ]; then
        firewall-cmd --direct --remove-rule $FAMILY filter $CHAIN 0 -m set --match-set $NAME src -j $BLOCKTYPE >&2 &&
            ipset -quiet flush $NAME >&2 &&
            ipset -quiet destroy $NAME >&2 ||
            {
                sleep 1
                ipset -quiet destroy $NAME >&2
            }
    elif [ "$CMD" = nft ]; then
        nft delete table inet $NAME
    fi >&2
}

check() {
    if [ "$CMD" = ipset ]; then
        ipset -terse list $NAME
    elif [ "$CMD" = nft ]; then
        nft list set inet $NAME $NAME
    fi >/dev/null
}

ban() {
    if [ "$CMD" = ipset ]; then
        ipset -exist -quiet add $NAME "$1"
    elif [ "$CMD" = nft ]; then
        nft add element inet $NAME $NAME "{ $1 }"
    fi >&2
}

unban() {
    if [ "$CMD" = ipset ]; then
    ipset -exist -quiet del $NAME "$1"
    elif [ "$CMD" = nft ]; then
        nft delete element inet $NAME $NAME "{ $1 }"
    fi >&2
}

dispatch() {
    action=$1
    ip=${2-}

    [ -n "$action" ] || {
        printf 'FAIL\n'
        return 0
    }

    echo "$action${ip:+ $ip}" >&2

    case "$action" in
        START)
            if check; then
                printf 'OK\n'
            else
                start && printf 'OK\n' || printf 'FAIL\n'
            fi
            ;;
        STOP)
            if check; then
                stop && printf 'OK\n' || printf 'FAIL\n'
            else
                printf 'OK\n'
            fi
            ;;
        CHECK)
            check && printf 'OK\n' || printf 'FAIL\n'
            ;;
        BAN)
            ban "$ip" && printf 'OK\n' || printf 'FAIL\n'
            ;;
        UNBAN)
            unban "$ip" && printf 'OK\n' || printf 'FAIL\n'
            ;;
        *)
            printf 'FAIL\n'
            ;;
    esac
}

{
    if IFS= read -r action param; then
        dispatch "${action}" "${param}"
    else
        printf 'FAIL\n'
    fi 2>&1 1>&3 | logger -t fail2ban-fw
} 3>&1
