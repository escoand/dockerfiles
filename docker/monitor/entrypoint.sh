#!/bin/sh

set -e

curl -fNsS --unix-socket /var/run/docker.sock http://localhost/events |
    jq -r --unbuffered '
        select(
            (.status=="health_status" and .HealthStatus=="healthy") | not
        ) |
        [ (.time | localtime | strftime("%Y-%m-%d %H:%M:%S")), .Type, .Actor.Attributes.name // .from, .HealthStatus // .Action // .status ] |
        join(" ")
    '
