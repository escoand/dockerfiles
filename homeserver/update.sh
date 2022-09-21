#!/bin/sh

CONTAINERCMD="docker.io/containrrr/watchtower --run-once --cleanup"
SOCKET=/run/user/$(id -u)/podman/podman.sock

git pull --all

# get command
if command -v podman >/dev/null 2>&1; then
	podman run --security-opt label=disable -it --rm -v "$SOCKET:/var/run/docker.sock:ro" $CONTAINERCMD
elif command -v docker >/dev/null 2>&1; then
	sudo docker -H "unix://$SOCKET" run --rm $CONTAINERCMD
fi
