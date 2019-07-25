ARG QEMUTAG
ARG BUILD_FROM

FROM multiarch/debian-debootstrap:${QEMUTAG}-stretch AS qemu
FROM $BUILD_FROM

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin
COPY ../hassio-nextcloud/run_addon.sh /

RUN apt-get update && \
    apt-get install --no-install-recommends -y jq && \
    sed -i 's|/var/www/html|/data/nextcloud|g' \
        /entrypoint.sh /var/spool/cron/crontabs/www-data && \
    rm -rf /tmp/dlib /usr/src/php/ext/pdlib /var/lib/apt/lists/* && \
    rm -rf /usr/bin/qemu-*-static

ENTRYPOINT ["/run_addon.sh"]
