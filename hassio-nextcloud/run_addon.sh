#!/bin/sh -e

for DIR in /data/nextcloud /share/nextcloud; do
    [ -d "${DIR}" ] && continue
    mkdir -p "${DIR}" 
    chown -R www-data:root "${DIR}"
    chmod -R g=u "${DIR}"
done

eval $(jq --raw-output '.env_var | .[] | "export " + .name + "=\"" + .value + "\""' /data/options.json)

/entrypoint.sh "$@"
