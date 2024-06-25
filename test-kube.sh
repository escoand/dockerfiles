#!/bin/bash

set -euo pipefail

trap teardown EXIT TERM INT

KUBEDIR=kube
TMP=$(mktemp -d)
echo $TMP

# shellcheck disable=SC2317
teardown() {
  [ -f "$TMP/teardown" ] && return
  touch "$TMP/teardown"
  echo "# tear down"
  find "$KUBEDIR" secrets*.sample.yaml -name '*.yaml' -exec podman kube play --down --force {} \; >/dev/null
  sed -n 's/^[[:blank:]]*claimName:[[:blank:]]*//p' "$KUBEDIR"/*.yaml |
    xargs podman volume rm -f >/dev/null
  rm -fr "$TMP"
}

log() {
  echo "$(date "+%Y-%m-%d %H:%I:%S") $@"
}

healthy() {
  find "$KUBEDIR" -name '*.yaml' |
    sed 's|^.*/\(.*\)\.yaml|\1-pod-\1|' |
    xargs podman wait --condition healthy >/dev/null
}

getsecret() {
  podman secret inspect "${2:-secrets}" --showsecret --format '{{.SecretData}}' |
    sed -n "s/^[[:blank:]]*$1:[[:blank:]][[:blank:]]*//p" |
    base64 -d
}

endtoend() {
  DOMAIN=$1
  PAGE=$2
  RESULT=$3
  RC=0
  shift 3
  {
    set -x
    # shellcheck disable=SC2015
    {
      curl -ikLsS --noproxy "*" -o "$TMP/output" "$@" \
        --connect-to "$DOMAIN:80:127.0.0.1:8080" \
        --connect-to "$DOMAIN:443:127.0.0.1:8443" \
        "http://$DOMAIN/$PAGE" ||
        [ $? = 47 ] # ignore max redirect
    } && grep -iq "$RESULT" "$TMP/output" || RC=$?
    set +x
  } >"$TMP/endtoend" 2>&1
  if [ $RC != 0 ]; then
    echo "#   -> failed:"
    cat "$TMP/endtoend"
    echo "#   -> output:"
    cat "$TMP/output"
  fi
  return $RC
}

log "patch pods for testing"
sed -i \
  -e '/^[[:blank:]]*env:/ {' \
  -e 'a\        - { name: NEXTCLOUD_ADMIN_USER, value: admin }' \
  -e 'a\        - { name: NEXTCLOUD_ADMIN_PASSWORD, value: admin }' \
  -e '}' \
  "$KUBEDIR/nextcloud.yaml"
sed -i \
  -e "s|/run/user/1000/|${XDG_RUNTIME_DIR:-/run/user/1000}/|" \
  "$KUBEDIR/dozzle.yaml"

log "create pods"
find secrets*.sample.yaml "$KUBEDIR" -name '*.yaml' -print -exec podman kube play --quiet --start=false {} \; >/dev/null

log "create databases"
podman pod start mariadb-pod >/dev/null
podman wait --condition healthy mariadb-pod-mariadb >/dev/null
sed -n 's/^[[:blank:]]*key:[[:blank:]][[:blank:]]*\(.*\)_db_name.*/\1/p' "$KUBEDIR"/*.yaml |
  xargs -n1 ./db_usr_pwd.sh
./db_usr_pwd.sh wordpress wordpress1

log "start pods"
podman pod start -a >/dev/null

log "wait for healthy state"
healthy

log "test Dozzle end-to-end"
#PWD=$(getsecret dozzle_password)
USR=$(getsecret dozzle_user)
DOMAIN=$(getsecret nextcloud_domain)
endtoend "$DOMAIN" dozzle/ "^HTTP/[1-9\.]* 200" --location-trusted --user "$USR:$USR"

log "test Nextcloud end-to-end"
DOMAIN=$(getsecret nextcloud_domain)
endtoend "$DOMAIN" status.php '"installed":true'

log "test Redir end-to-end"
DOMAIN=$(getsecret redir_domain)
TARGET=$(getsecret redir_target)
endtoend "$DOMAIN" test.php "Location: $TARGET" --max-redirs 1

log "test Wordpress end-to-end"
DOMAIN=$(getsecret wordpress1_domain)
endtoend "$DOMAIN" wp-admin/install.php "^HTTP/[1-9\.]* 200"

log "test signal stability"
podman kill -a -s WINCH >/dev/null
sleep 5
healthy

log "show final state"
podman ps -a
