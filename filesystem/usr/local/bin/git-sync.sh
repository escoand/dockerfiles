#!/bin/sh

set -e

changed=0

if [ ! -d "$LOCAL/.git" ]; then
    git clone "$REPO" "$LOCAL"
    mkdir -p ~/.config/containers
    if [ -d "$LOCAL/quadlet" ]; then
        ln -sfn "$LOCAL/quadlet" ~/.config/containers/systemd
    else
        ln -sfn "$LOCAL/systemd" ~/.config/containers/systemd
    fi
    changed=1
else
    before_rev=$(git -C "$LOCAL" rev-parse HEAD)
    git -C "$LOCAL" pull --ff-only
    after_rev=$(git -C "$LOCAL" rev-parse HEAD)

    if [ "$before_rev" != "$after_rev" ]; then
        changed=1
    fi
fi

if [ "$changed" -eq 1 ]; then
    touch "$MARKER"
else
    rm -f "$MARKER"
fi
