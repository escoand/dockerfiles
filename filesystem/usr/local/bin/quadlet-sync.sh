#!/bin/sh

set -e

rm -f "$MARKER"

if [ ! -d "$LOCAL/.git" ]; then
    git clone --branch "$REPOBRANCH" "$REPO" "$LOCAL"
    mkdir -p ~/.config/containers
    ln -sfn "$LOCAL/$REPODIR" ~/.config/containers/systemd
    touch "$MARKER"
else
    before_rev=$(git -C "$LOCAL" rev-parse HEAD)
    git -C "$LOCAL" pull --ff-only
    after_rev=$(git -C "$LOCAL" rev-parse HEAD)

    [ "$before_rev" != "$after_rev" ] &&
    touch "$MARKER"
fi