#!/bin/sh
# shellcheck disable=SC2155

export HOSTNAME="$(hostname)"
export CONTAINER_ID="$(dd if=/dev/urandom | tr -cd '0-9a-f' | head -c12)"
export CONTAINER_NAME=journalctl

SOCK=/run/journald-proxy/docker.sock

mkdir -p ${SOCK%/*}

socat TCP-LISTEN:2375,reuseaddr,fork EXEC:/handler.sh &

exec socat UNIX-LISTEN:$SOCK,reuseaddr,fork,unlink-early,mode=0666 EXEC:/handler.sh
