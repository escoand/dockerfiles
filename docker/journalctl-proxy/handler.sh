#!/bin/bash

shopt -s lastpipe

urldecode() {
    : "${*//+/ }"
    echo -e "${_//%/\\x}"
}

result() {
    typeset headers
    if [ "$1" = -h ]; then
        headers=FALSE
        shift
    fi
    code=$1
    shift
    echo "  > result $code: $*" >&2
    printf 'HTTP/1.1 %i %s\r\nApi-Version: 1.41\r\n' "$code" "$*"
    [ "$headers" != FALSE ] && printf 'Connection: close\r\n\r\n'
}

info() {
    cpu=$(grep -c ^processor /proc/cpuinfo)
    mem=$(awk '/MemTotal:/ {print $2*1024}' /proc/meminfo)
    cat <<END
{
  "ID": "$HOSTNAME",
  "Containers": 1,
  "ContainersRunning": 1,
  "ContainersPaused": 0,
  "ContainersStopped": 0,
  "Images": 53,
  "NCPU": $cpu,
  "MemTotal": $mem,
  "ServerVersion": "dummy",
  "SwapFree": 4294967296,
  "SwapTotal": 4294967296
}
END
}

list() {
    start=$(awk '/^btime/ {print $2}' /proc/stat)
    cat <<END
[
  {
    "Id": "$CONTAINER_ID",
    "Names": ["/$CONTAINER_NAME"],
    "Image": "docker.io/library/alpine:latest",
    "ImageID": "sha256:9234e8fb04c47cfe0f49931e4ac7eb76fa904e33b7f8576aec0501c085f02516",
    "Command": "/bin/sh",
    "Created": $start,
    "Ports": [],
    "Labels": {},
    "State": "running",
    "NetworkSettings": { "Networks": null },
    "Mounts": [],
    "Name": "",
    "Config": null,
    "NetworkingConfig": null,
    "Platform": null,
    "DefaultReadOnlyNonRecursive": false
  }
]
END
}

container() {
    start=$(awk '/^btime/ {print "@" $2}' /proc/stat | xargs date -u -Ins -d)
    cat <<END
{
  "Id": "$CONTAINER_ID",
  "Created": "$start",
  "Path": "/bin/sh",
  "Args": ["/bin/sh"],
  "State": {
    "Status": "running",
    "Running": true,
    "Paused": false,
    "Restarting": false,
    "OOMKilled": false,
    "Dead": false,
    "Pid": 4470,
    "ExitCode": 0,
    "Error": "",
    "StartedAt": "$start",
    "FinishedAt": "0001-01-01T00:00:00Z"
  },
  "Image": "sha256:9234e8fb04c47cfe0f49931e4ac7eb76fa904e33b7f8576aec0501c085f02516",
  "Name": "/$CONTAINER_NAME",
  "RestartCount": 0,
  "Driver": "overlay",
  "Platform": "linux",
  "MountLabel": "",
  "ProcessLabel": "",
  "AppArmorProfile": "",
  "ExecIDs": [],
  "HostConfig": {},
  "GraphDriver": {},
  "SizeRootFs": 0,
  "Mounts": [],
  "Config": {},
  "NetworkSettings": {}
}
END
}

stats() {
    cat <<END
{
  "read": "2025-09-17T10:48:21.637410081+02:00",
  "preread": "2025-09-17T10:48:21.634478364+02:00",
  "num_procs": 0,
  "cpu_stats": {
    "cpu_usage": {
      "total_usage": 1718576000,
      "usage_in_kernelmode": 849178,
      "usage_in_usermode": 1717726822
    },
    "system_cpu_usage": 6461561673000,
    "online_cpus": 20,
    "cpu": 0,
    "throttling_data": {
      "periods": 0,
      "throttled_periods": 0,
      "throttled_time": 0
    }
  },
  "memory_stats": { "usage": 782336, "limit": 16577101824 },
  "name": "$CONTAINER_NAME",
  "id": "$CONTAINER_ID"
}
END
}

logs() {
    journalctl "$@"
}

# request
typeset method uri
while read -r key value; do
    if [ -z "$method" ]; then
        method=$key
        uri=$(urldecode "${value% *}")
        echo "### METHOD: $method" >&2
        echo "### URI:    $uri" >&2
    # end of headers
    elif [ -z "$key" ] || [ "$key" = $'\r' ]; then
        break
    else
        echo "##### $key $value" >&2
    fi
done

# handle
if [[ "$uri" = /_ping ]]; then
    result 200 OK
elif [[ "$uri" = /*/info ]]; then
    result 200 OK
    info
elif [[ "$uri" = /*/events ]]; then
    result 200 OK
    sleep infinity
elif [[ "$uri" = /*/containers/json* ]]; then
    result 200 OK
    list
elif [[ "$uri" = /*/containers/$CONTAINER_ID/json* ]]; then
    result 200 OK
    container
elif [[ "$uri" = /*/containers/$CONTAINER_ID/stats* ]]; then
    result 200 OK
    stats
elif [[ "$uri" = /*/containers/$CONTAINER_ID/logs* ]]; then
    typeset relative args=()
    echo "${uri#*\?}" | tr '&' '\n' | while IFS='=' read -r key value; do
        if [ "$key" = follow ] && [ -n "$value" ]; then
            args[${#args[@]}]=--follow
        elif [ "$key" = since ]; then
            if [[ "$value" = -* ]]; then
                relative=TRUE
                date=$(date -u +"%Y-%m-%d %H:%M:%S" -d "@${value#-}") &&
                    args[${#args[@]}]="--until=$date"
            else
                date=$(date -u +"%Y-%m-%d %H:%M:%S" -d "@$value") &&
                    args[${#args[@]}]="--since=$date"
            fi
        elif [ "$key" = timestamps ] && [ -n "$value" ]; then
            args[${#args[@]}]=--output=short-iso
        elif [ "$key" = tail ]; then
            args[${#args[@]}]="--lines=${value:-all}"
        elif [ "$key" = until ]; then
            if [ "$relative" != TRUE ]; then
                date=$(date -u +"%Y-%m-%d %H:%M:%S" -d "@$value") &&
                    args[${#args[@]}]="--until=$date"
            fi
        fi
    done
    result -h 200 OK
    printf "Transfer-Encoding: chunked\r\n\r\n"
    logs "${args[@]}" |
    awk '{
        len  = length($0) + 2
        b1 = int(len / (2^24)) % 256
        b2 = int(len / (2^16)) % 256
        b3 = int(len / (2^8))  % 256
        b4 = len               % 256
        printf("%x\r\n%c%c%c%c%c%c%c%c%s\r\n\r\n", len + 8, 2,0,0,0, b1,b2,b3,b4, $0)
    }
    '
else
    result 404 Not Found
fi
