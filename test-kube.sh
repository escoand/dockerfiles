#!/bin/bash

set -euo pipefail

trap teardown EXIT TERM INT

KUBEDIR=kube
TMP=$(mktemp)

# shellcheck disable=SC2317
teardown() {
  [ -s "$TMP" ] && return
  date > "$TMP"
  echo "# tear down"
  find "$KUBEDIR" secrets.sample.yaml -name '*.yaml' -exec podman kube play --down --force {} \; >/dev/null
  sed -n 's/^[[:blank:]]*claimName:[[:blank:]]*//p' "$KUBEDIR"/*.yaml |
  xargs podman volume rm -f >/dev/null
  rm -f "$TMP"
}

echo "# patch pods for testing"
sed -i \
  -e '/^[[:blank:]]*env:/ {' \
  -e 'a\        - { name: NEXTCLOUD_ADMIN_USER, value: admin }' \
  -e 'a\        - { name: NEXTCLOUD_ADMIN_PASSWORD, value: admin }' \
  -e '}' \
  "$KUBEDIR/nextcloud.yaml"
sed -i \
  -e "s|/run/user/1000/|${XDG_RUNTIME_DIR:-/run/user/1000}/|" \
  "$KUBEDIR/dozzle.yaml"

echo "# create pods"
find secrets.sample.yaml "$KUBEDIR" -name '*.yaml' -print -exec podman kube play --quiet --start=false {} \; >/dev/null
podman run --rm -q -v nextcloud:/data:z alpine mkdir -p /data/apps /data/config /data/data

echo "# create databases"
podman pod start mariadb-pod >/dev/null
podman wait --condition healthy mariadb-pod-mariadb >/dev/null
sed -n 's/^[[:blank:]]*key:[[:blank:]][[:blank:]]*\(.*\)_db_name.*/\1/p' "$KUBEDIR"/*.yaml |
xargs -n1 ./db_usr_pwd.sh

echo "# start pods"
podman pod start -a >/dev/null

echo "# wait for healthy state"
find "$KUBEDIR" -name '*.yaml' |
sed 's|^.*/\(.*\)\.yaml|\1-pod-\1|' |
xargs podman wait --condition healthy >/dev/null
RC=$?

echo "# test ended with RC=$RC"
exit $RC