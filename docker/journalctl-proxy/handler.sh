#!/bin/bash

export JOURNAL_ID=_journal

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

findService() {
    [ "$1" = "$JOURNAL_ID" ] && return
    systemctl --user show --type=service --property=InvocationID,Id |
        grep -A1 -B1 -F "InvocationID=${1#_}" |
        grep ^Id= |
        cut -d= -f2-
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
    systemctl --user show --all --type=service |
        jq --slurp --raw-input '
            split("\n\n") |
            map(
                split("\n") |
                map(
                    select(.!="") |
                    split("=") |
                    {"key": .[0], "value": (.[1:] | join("="))}
                ) |
                from_entries |
                {
                    Created: (.ExecMainStartTimestamp | strptime("%a %Y-%m-%d %H:%M:%S %Z")? | strftime("%s") | tonumber? // null),
                    Id: ("_" + .InvocationID),
                    Names: (.Names | split(" ") | map("/" + .)),
                    State: .SubState
                }
            ) + [{
                Created: null,
                Id: (env.JOURNAL_ID + "            "),
                Names: ["/" + env.JOURNAL_ID],
                State: "running"
            }]
        '
}

container() {
    systemctl --user show "$1" |
        NAME="$1" jq --slurp --raw-input '
            split("\n") |
            map(select(.!="") | split("=") | {"key": .[0], "value": (.[1:] | join("="))}) |
            from_entries |
            {
                Created: (.ExecMainStartTimestamp | strptime("%a %Y-%m-%d %H:%M:%S %Z")? | strftime("%Y-%m-%dT%H:%M:%S.000000Z") // null),
                HostConfig: {
                    Memory: (.MemoryAvailable | tonumber? // null),
                },
                Id: ("_" + .InvocationID),
                Name: env.NAME,
                RestartCount: (.NRestarts | tonumber? // null),
                State: {
                    Status: .SubState
                }
            }
        '
}

stats() {
    systemctl --user show "$1" |
        NAME="$1" jq --slurp --raw-input '
            split("\n") |
            map(select(.!="") | split("=") | {"key": .[0], "value": (.[1:] | join("="))}) |
            from_entries |
            {
                id: ("_" + .InvocationID),
                name: env.NAME,
                pids_stats: {
                    current: (.MainPID | tonumber? // null)
                },
                memory_stats: {
                    limit: (.MemoryAvailable | tonumber? // null),
                    max_usage: (.MemoryPeak | tonumber? // null),
                    usage: (.MemoryCurrent | tonumber? // null)
                }
            }'
}

# request
typeset method uri query
while read -r key value; do
    if [ -z "$method" ]; then
        method=$key
        uri=$(urldecode "${value% *}")
        echo "$method $uri" >&2
        if [[ $uri = *\?* ]]; then
            query=${uri#*\?}
            uri=${uri%%\?*}
        fi
    # end of headers
    elif [ -z "$key" ] || [ "$key" = $'\r' ]; then
        break
    fi
done

# handle
if [[ $uri = /_ping ]]; then
    result 200 OK
elif [[ $uri = /*/info ]]; then
    result 200 OK
    info
elif [[ $uri = /*/events ]]; then
    result 200 OK
    sleep infinity
elif [[ $uri = /*/containers/json ]]; then
    result 200 OK
    list
elif [[ $uri = /*/containers/*/json ]]; then
    container=$(echo "$uri" | cut -d/ -f4)
    service=$(findService "$container")
    if [ -z "$service" ]; then
        result 404 Not found
        printf '{"message": "No such container: %s"}' "$container"
    else
        # this is failing - don't know why
        #result 200 OK
        #container "$service"
        result 501 Not Implemented
    fi
elif [[ $uri = /*/containers/*/stats ]]; then
    container=$(echo "$uri" | cut -d/ -f4)
    service=$(findService "$container")
    if [ -z "$service" ]; then
        result 404 Not found
        printf '{"message": "No such container: %s"}' "$container"
    else
        result 200 OK
        if [[ "$query" = *stream=* ]]; then
            while true; do stats "$service"; done
        else
            stats "$service"
        fi
    fi
elif [[ $uri = /*/containers/*/logs ]]; then
    typeset relative args=(--quiet)
    echo "$query" | tr '&' '\n' | while IFS='=' read -r key value; do
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
    container=$(echo "$uri" | cut -d/ -f4)
    if [ "$container" != "$JOURNAL_ID" ]; then
        service=$(findService "$container")
        args[${#args[@]}]="USER_UNIT=$service"
    fi
    result -h 200 OK
    journalctl "${args[@]}" |
        gawk '
            BEGIN { printf "Transfer-Encoding: chunked\r\n\r\n" }
            {
                len  = length($0) + 2
                b1 = int(len / (2^24)) % 256
                b2 = int(len / (2^16)) % 256
                b3 = int(len / (2^8))  % 256
                b4 = len               % 256
                printf("%x\r\n%c%c%c%c%c%c%c%c%s\r\n\r\n", len + 8, 2,0,0,0, b1,b2,b3,b4, $0)
                system("")
            }
            END { printf("0\r\n\r\n") }
        '
# actions
elif [[ $method = POST && $uri = /*/containers/*/restart ]]; then
    container=$(echo "$uri" | cut -d/ -f4)
    service=$(findService "$container")
    if [ -z "$service" ]; then
        result 404 Not found
        printf '{"message": "No such container: %s"}' "$container"
    else
        systemctl --user restart "$service" &&
        result 200 OK ||
        result 500
    fi
else
    result 501 Not Implemented
fi
