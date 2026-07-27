#!/bin/bash
# shellcheck disable=SC2015

set -eu

FAMILY=ipv4
CHAIN=INPUT_direct
NAME=fail2ban
NAME4=${NAME}4
NAME6=${NAME}6
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
            nft add set inet $NAME $NAME4 "{ type ipv4_addr; flags dynamic; }" &&
            nft add set inet $NAME $NAME6 "{ type ipv6_addr; flags dynamic; }" &&
            nft add chain inet $NAME input "{ type filter hook input priority 0; }" &&
            nft add rule inet $NAME input ip saddr @$NAME4 drop &&
            nft add rule inet $NAME input ip6 saddr @$NAME6 drop
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
        nft list set inet $NAME $NAME4 >/dev/null &&
            nft list set inet $NAME $NAME6 >/dev/null
    fi >/dev/null
}

is_ipv6() {
    case "$1" in
    *:*) return 0 ;;
    *) return 1 ;;
    esac
}

ban() {
    if [ "$CMD" = ipset ]; then
        ipset -exist -quiet add $NAME "$1"
    elif [ "$CMD" = nft ]; then
        if is_ipv6 "$1"; then
            nft add element inet $NAME $NAME6 "{ $1 }"
        else
            nft add element inet $NAME $NAME4 "{ $1 }"
        fi
    fi >&2
}

unban() {
    if [ "$CMD" = ipset ]; then
        ipset -exist -quiet del $NAME "$1"
    elif [ "$CMD" = nft ]; then
        if is_ipv6 "$1"; then
            nft delete element inet $NAME $NAME6 "{ $1 }"
        else
            nft delete element inet $NAME $NAME4 "{ $1 }"
        fi
    fi >&2
}

{
    if read -r action ip; then
        [ -n "$action" ] || {
            echo FAIL
            return 0
        }

        echo "$action${ip:+ $ip}" >&2

        case "$action" in
        START)
            if check; then
                echo OK
            else
                start && echo OK || echo FAIL
            fi
            ;;
        STOP)
            if check; then
                stop && echo OK || echo FAIL
            else
                echo OK
            fi
            ;;
        CHECK)
            check && echo OK || echo FAIL
            ;;
        BAN)
            ban "$ip" && echo OK || echo FAIL
            ;;
        UNBAN)
            unban "$ip" && echo OK || echo FAIL
            ;;

        *)
            echo FAIL
            ;;
        esac
    else
        echo FAIL
    fi 2>&1 1>&3 |
        logger -t fail2ban-fw
} 3>&1
