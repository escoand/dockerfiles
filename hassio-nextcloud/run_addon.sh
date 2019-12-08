#!/bin/sh -eu

TMP=$(mktemp)

for DIR in /data/nextcloud /share/nextcloud; do
    [ -d "${DIR}" ] && continue
    mkdir -p "${DIR}" 
    chown -R www-data:root "${DIR}"
    chmod -R g=u "${DIR}"
done

cat << 'EOF' |
    .mysql.database    MYSQL_DATABASE
    .mysql.host        MYSQL_HOST
    .mysql.user        MYSQL_USER
    .mysql.password    MYSQL_PASSWORD
    .postgres.database POSTGRES_DB
    .postgres.host     POSTGRES_HOST
    .postgres.user     POSTGRES_USER
    .postgres.password POSTGRES_PASSWORD
    .admin.user        NEXTCLOUD_ADMIN_USER
    .admin.password    NEXTCLOUD_ADMIN_PASSWORD
    .trusted_domain    NEXTCLOUD_TRUSTED_DOMAINS
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
    VALUE=$(jq -r "$CONF" /data/options.json | grep -vFx null)
    [ -n "$VALUE" ] && printf 'export %s="%s"\n' "$ENVVAR" "$VALUE" >> "$TMP"
done
. "$TMP"
rm -rf "$TMP"

sh /entrypoint.sh "$@"
