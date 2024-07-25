#!/bin/sh

getsecret() {
  podman secret inspect "${2:-secrets}" --showsecret --format '{{.SecretData}}' |
  sed -n "s/^[[:blank:]]*$1:[[:blank:]][[:blank:]]*//Ip" |
  base64 -d
}

PREFIX=$1
NAME=$(getsecret "${PREFIX}_name" "$2")
[ -z "$NAME" ] && NAME=$(getsecret "${PREFIX}_database" "$2")
PASS=$(getsecret "${PREFIX}_password" "$2")
USR=$(getsecret "${PREFIX}_user" "$2")

if [ -z "$PREFIX" ] || [ -z "$NAME" ] || [ -z "$PASS" ] || [ -z "$USR" ]; then
  echo prefix not set or secrets not found >&2
  exit 1
fi

cat << END |
CREATE DATABASE IF NOT EXISTS $NAME;
CREATE USER IF NOT EXISTS "$USR"@"%";
SET PASSWORD FOR "$USR"@"%" = PASSWORD("$PASS");
GRANT ALL PRIVILEGES ON $NAME.* TO "$USR"@"%";
FLUSH PRIVILEGES;
END
podman exec -i mariadb-app \
  sh -c 'mariadb --password="$MARIADB_ROOT_PASSWORD"'
