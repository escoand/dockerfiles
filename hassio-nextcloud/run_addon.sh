#!/bin/sh -e

for DIR in /data/nextcloud /share/nextcloud; do
    [ -d "${DIR}" ] && continue
    mkdir -p "${DIR}" 
    chown -R www-data:root "${DIR}"
    chmod -R g=u "${DIR}"
done

export MYSQL_DATABASE="$(jq --raw-output .mysql.database /data/options.json)"
export MYSQL_HOST="$(jq --raw-output .mysql.host /data/options.json)"
export MYSQL_USER="$(jq --raw-output .mysql.user /data/options.json)"
export MYSQL_PASSWORD="$(jq --raw-output .mysql.password /data/options.json)"
export POSTGRES_DB="$(jq --raw-output .postgres.database /data/options.json)"
export POSTGRES_HOST="$(jq --raw-output .postgres.host /data/options.json)"
export POSTGRES_USER="$(jq --raw-output .postgres.user /data/options.json)"
export POSTGRES_PASSWORD="$(jq --raw-output .postgres.password /data/options.json)"
export NEXTCLOUD_ADMIN_USER="$(jq --raw-output .admin.user /data/options.json)"
export NEXTCLOUD_ADMIN_PASSWORD="$(jq --raw-output .admin.password /data/options.json)"
export NEXTCLOUD_TRUSTED_DOMAINS="$(jq --raw-output .trusted_domains /data/options.json)"
export REDIS_HOST="$(jq --raw-output .redis.host /data/options.json)"
export REDIS_HOST_PORT="$(jq --raw-output .redis.port /data/options.json)"
export SMTP_HOST="$(jq --raw-output .smtp.host /data/options.json)"
export SMTP_SECURE="$(jq --raw-output .smtp.secure /data/options.json)"
export SMTP_PORT="$(jq --raw-output .smtp.port /data/options.json)"
export SMTP_AUTHTYPE="$(jq --raw-output .smtp.authtype /data/options.json)"
export SMTP_NAME="$(jq --raw-output .smtp.name /data/options.json)"
export SMTP_PASSWORD="$(jq --raw-output .smtp.password /data/options.json)"
export MAIL_FROM_ADDRESS="$(jq --raw-output .mail.from_address /data/options.json)"
export MAIL_DOMAIN="$(jq --raw-output .mail.domain /data/options.json)"

/entrypoint.sh "$@"
