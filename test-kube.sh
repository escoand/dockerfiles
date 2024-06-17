#!/bin/bash

set -euo pipefail

trap teardown EXIT TERM INT

KUBEDIR=kube
TMP1=$(mktemp)
TMP2=$(mktemp)

# shellcheck disable=SC2317
teardown() {
  [ -s "$TMP1" ] && return
  date >"$TMP1"
  echo "# tear down"
  find "$KUBEDIR" secrets.sample.yaml -name '*.yaml' -exec podman kube play --down --force {} \; >/dev/null
  sed -n 's/^[[:blank:]]*claimName:[[:blank:]]*//p' "$KUBEDIR"/*.yaml |
    xargs podman volume rm -f >/dev/null
  rm -f "$TMP1" "$TMP2"
}

getsecret() {
  podman secret inspect secrets --showsecret --format '{{.SecretData}}' |
    sed -n "s/^[[:blank:]]*$1:[[:blank:]][[:blank:]]*//p" |
    base64 -d
}

endtoend() {
  DOMAIN=$1
  PAGE=$2
  RESULT=$3
  shift 3
  if curl -ikLsS --noproxy "*" -o "$TMP2" "$@" \
    --connect-to "$DOMAIN:80:127.0.0.1:8080" \
    --connect-to "$DOMAIN:443:127.0.0.1:8443" \
    "http://$DOMAIN/$PAGE" ||
    # ignore max redir error
    [ $? = 47 ]; then
    grep -Fq "$RESULT" "$TMP2"
  else
    echo "#   -> failed"
    cat "$TMP2"
    return 1
  fi
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

echo "# test Nextcloud end-to-end"
DOMAIN=$(getsecret nextcloud_domain)
endtoend "$DOMAIN" status.php '"installed":true'

echo "# test Redir end-to-end"
DOMAIN=$(getsecret redir_domain)
TARGET=$(getsecret redir_target)
endtoend "$DOMAIN" test.php "Location: $TARGET" --max-redirs 1 --no-show-error

echo "# test Wordpress end-to-end"
DOMAIN=$(getsecret wordpress_domain)
endtoend "$DOMAIN" wp-admin/install.php "HTTP/1.1 200"
