#!/usr/bin/bash

MASTER_HOST=$1
MASTER_PORT=${2:-22}
MASTER_USER=${3:-satellite}

while true; do
	TUNNEL_PORT=${4:-$((23750+RANDOM%10))}
	echo "forward local docker daemon to $MASTER_USER@$MASTER_HOST:$MASTER_PORT at port $TUNNEL_PORT"
	ssh -gN "$MASTER_HOST" \
		-l "$MASTER_USER" \
		-p "$MASTER_PORT" \
		-R "0.0.0.0:$TUNNEL_PORT:/var/run/docker.sock" \
		-o ExitOnForwardFailure=yes \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null
	sleep 5
done
