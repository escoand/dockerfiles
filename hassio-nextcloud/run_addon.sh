#!/bin/sh -eu

TMP=$(mktemp)

for DIR in /data/nextcloud /share/nextcloud; do
    [ -d "${DIR}" ] && continue
    mkdir -p "${DIR}" 
    chown -R www-data:root "${DIR}"
    chmod -R g=u "${DIR}"
done

export NEXTCLOUD_DATA_DIR=/share/nextcloud
export NEXTCLOUD_UPDATE=1
cat << EOF |
    .mysql.database    MYSQL_DATABASE
    .mysql.host        MYSQL_HOST
    .mysql.user        MYSQL_USER
    .mysql.password    MYSQL_PASSWORD
    .postgres.database POSTGRES_DB
    .postgres.host     POSTGRES_HOST
    .postgres.user     POSTGRES_USER
    .postgres.password POSTGRES_PASSWORD
    .redis.host        REDIS_HOST
    .redis.port        REDIS_HOST_PORT
    .smtp.host         SMTP_HOST
    .smtp.secure       SMTP_SECURE
    .smtp.port         SMTP_PORT
    .smtp.authtype     SMTP_AUTHTYPE
    .smtp.name         SMTP_NAME
    .smtp.password     SMTP_PASSWORD
    .mail.from_address MAIL_FROM_ADDRESS
    .mail.domain       MAIL_DOMAIN
EOF
while read -r CONF ENVVAR; do
    CMD=$(printf '%s | select(.!=null) | tostring | "export %s=\""+.+"\""' "$CONF" "$ENVVAR")
    jq -r "$CMD" /data/options.json >> "$TMP"
done
. "$TMP"
rm -rf "$TMP"

sh /entrypoint.sh "$@"
