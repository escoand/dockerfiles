#!/bin/bash

cat <<END |
# dozzle
DOZZLE_PASSWORD                 dozzle
DOZZLE_USER                     dozzle

# monitor
MAIL_FROM                       admin@localhost
MAIL_HOST                       smtp.localhost
MAIL_PASSWORD                   password
MAIL_PORT                       587
MAIL_TO                         admin@localhost
MAIL_USER                       admin@localhost

# mariadb
MARIADB_ROOT_PASSWORD           password

# nextcloud
NEXTCLOUD_DATABASE              nextcloud
NEXTCLOUD_DATABASE_PASSWORD     nextcloud
NEXTCLOUD_DATABASE_USER         nextcloud
NEXTCLOUD_DOMAIN                cloud.localhost
REDIR_DOMAIN                    redir.localhost
REDIR_TARGET                    http://cloud.localhost

# claper
BASE_URL                        /
CLAPER_DOMAIN                   claper.localhost
DATABASE_URL                    claper
POSTGRES_DB                     claper
POSTGRES_PASSWORD               claper
POSTGRES_USER                   claper
SECRET_KEY_BASE                 secret_key
OIDC_CLIENT_ID                  client_id
OIDC_CLIENT_SECRET              client_secret
OIDC_ISSUER                     oidc_issuer

# restic
RESTIC_ACCESS_KEY               access_key
RESTIC_PASSWORD                 password
RESTIC_REPOSITORY               repo
RESTIC_SECRET_KEY               secret_key

# tracker
TRACKER_API_AUTHENTICATION      tracker
TRACKER_API_ENCRYPTION          tracker
TRACKER_API_MESSAGE             tracker
TRACKER_DOMAIN                  tracker.localhost
TRACKER_PASSWORD                tracker
TRACKER_USER                    tracker

# vm
VM_PASSWORD                     vm
VM_USER                         vm

# wordpress
WORDPRESS1_DOMAIN               wp1.localhost
WORDPRESS2_DOMAIN               wp2.localhost
WORDPRESS3_DOMAIN               wp3.localhost
WORDPRESS4_DOMAIN               wp4.localhost
WORDPRESS5_DOMAIN               wp5.localhost
END

while read -r key value; do
    [[ $key = "#"* || -z $value ]] && continue
    printf %s "$value" | podman secret create "$key" -
done