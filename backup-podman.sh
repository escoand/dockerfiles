#!/bin/sh

# TODO make /secrets readable

set -eu

FORGETARGS="--keep-daily 1 --keep-weekly 3 --keep-monthly 3 --prune"
SECRETSPATH=$(podman system info --format "{{.Store.GraphRoot}}/secrets")
VOLUMEPATH=$(podman system info --format "{{.Store.VolumePath}}")

log() {
    printf "%s %s\n" "$(date +%Y-%m-%d\ %H:%M:%S)" "$*"
}

mountpoints() {
    podman volume ls --format "{{.Mountpoint}}\t{{.Anonymous}}" |
        awk -F'\t' '$2=="false"{print $1}'
}

mount() {
    log "mount volumes"
    podman volume ls --format "{{.Name}}\t{{.Anonymous}}" |
        awk -F'\t' '$2=="false"{print $1}' |
        xargs -l1 podman unshare podman volume mount >/dev/null
}

unmount() {
    log "unmount volumes"
    podman volume ls --format "{{.Name}}\t{{.Anonymous}}" |
        awk -F'\t' '$2=="false"{print $1}' |
        xargs -l1 podman unshare podman volume unmount >/dev/null
}

restic() {
    podman run --rm --name restic \
        --env RESTIC_HOST="$(hostname)" \
        --env RESTIC_PROGRESS_FPS=0.1 \
        --secret RESTIC_REPOSITORY,type=env \
        --secret RESTIC_PASSWORD,type=env \
        --secret B2_ACCOUNT_ID,type=env \
        --secret B2_ACCOUNT_KEY,type=env \
        --volume "$SECRETSPATH:/secrets:ro" \
        --volume "$VOLUMEPATH:/data:ro" \
        docker.io/restic/restic:latest "$@"
}

# custom command
if [ $# -gt 0 ]; then
    restic "$@"
    exit $?
fi

# check repo
log "check repo"
if ! restic cat config >/dev/null; then
    RC=$?

    # init repo
    if [ "$RC" -eq 10 ]; then
        log "init repo"
        restic init
    else
        exit $RC
    fi
fi

# mount volumes
trap "unmount; log exit" EXIT
mount

# backup
log "back up"
# shellcheck disable=SC2046
restic --json backup $(mountpoints | sed "s|^$VOLUMEPATH/|/data/|")

# cleanup
log "clean up"
# shellcheck disable=SC2086
restic --json forget $FORGETARGS
