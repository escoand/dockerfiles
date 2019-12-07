#!/bin/sh -e

for DIR in /data/nextcloud /share/nextcloud; do
    [ -d "${DIR}" ] && continue
    mkdir -p "${DIR}" 
    chown -R www-data:root "${DIR}"
    chmod -R g=u "${DIR}"
done

MYSQL_DATABASE="$(jq --raw-output .mysql.database /data/options.json)"
MYSQL_HOST="$(jq --raw-output .mysql.host /data/options.json)"
MYSQL_USER="$(jq --raw-output .mysql.user /data/options.json)"
MYSQL_PASSWORD="$(jq --raw-output .mysql.password /data/options.json)"
POSTGRES_DB="$(jq --raw-output .postgres.database /data/options.json)"
POSTGRES_HOST="$(jq --raw-output .postgres.host /data/options.json)"
POSTGRES_USER="$(jq --raw-output .postgres.user /data/options.json)"
POSTGRES_PASSWORD="$(jq --raw-output .postgres.password /data/options.json)"
NEXTCLOUD_ADMIN_USER="$(jq --raw-output .admin.user /data/options.json)"
NEXTCLOUD_ADMIN_PASSWORD="$(jq --raw-output .admin.password /data/options.json)"
NEXTCLOUD_TRUSTED_DOMAINS="$(jq --raw-output .trusted_domains /data/options.json)"
REDIS_HOST="$(jq --raw-output .redis.host /data/options.json)"
REDIS_HOST_PORT="$(jq --raw-output .redis.port /data/options.json)"
SMTP_HOST="$(jq --raw-output .smtp.host /data/options.json)"
SMTP_SECURE="$(jq --raw-output .smtp.secure /data/options.json)"
SMTP_PORT="$(jq --raw-output .smtp.port /data/options.json)"
SMTP_AUTHTYPE="$(jq --raw-output .smtp.authtype /data/options.json)"
SMTP_NAME="$(jq --raw-output .smtp.name /data/options.json)"
SMTP_PASSWORD="$(jq --raw-output .smtp.password /data/options.json)"
MAIL_FROM_ADDRESS="$(jq --raw-output .mail.from_address /data/options.json)"
MAIL_DOMAIN="$(jq --raw-output .mail.domain /data/options.json)"

[ -n "$MYSQL_DATABASE" ] && export MYSQL_DATABASE
[ -n "$MYSQL_HOST" ] && export MYSQL_HOST
[ -n "$MYSQL_USER" ] && export MYSQL_USER
[ -n "$MYSQL_PASSWORD" ] && export MYSQL_PASSWORD
[ -n "$POSTGRES_DB" ] && export POSTGRES_DB
[ -n "$POSTGRES_HOST" ] && export POSTGRES_HOST
[ -n "$POSTGRES_USER" ] && export POSTGRES_USER
[ -n "$POSTGRES_PASSWORD" ] && export POSTGRES_PASSWORD
[ -n "$NEXTCLOUD_ADMIN_USER" ] && export NEXTCLOUD_ADMIN_USER
[ -n "$NEXTCLOUD_ADMIN_PASSWORD" ] && export NEXTCLOUD_ADMIN_PASSWORD
[ -n "$NEXTCLOUD_TRUSTED_DOMAINS" ] && export NEXTCLOUD_TRUSTED_DOMAINS
[ -n "$REDIS_HOST" ] && export REDIS_HOST
[ -n "$REDIS_HOST_PORT" ] && export REDIS_HOST_PORT
[ -n "$SMTP_HOST" ] && export SMTP_HOST
[ -n "$SMTP_SECURE" ] && export SMTP_SECURE
[ -n "$SMTP_PORT" ] && export SMTP_PORT
[ -n "$SMTP_AUTHTYPE" ] && export SMTP_AUTHTYPE
[ -n "$SMTP_NAME" ] && export SMTP_NAME
[ -n "$SMTP_PASSWORD" ] && export SMTP_PASSWORD
[ -n "$MAIL_FROM_ADDRESS" ] && export MAIL_FROM_ADDRESS
[ -n "$MAIL_DOMAIN" ] && export MAIL_DOMAIN

/entrypoint.sh "$@"
