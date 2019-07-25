ARG ARCHALIAS
ARG BUILD_FROM

FROM multiarch/debian-debootstrap:${ARCHALIAS}-stretch AS qemu
FROM $BUILD_FROM

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin
COPY run_addon.sh /

RUN sed -i 's|/var/www/html|/data/nextcloud|g' /entrypoint.sh && \
    sed -i 's|/var/www/html|/data/nextcloud|g' /var/spool/cron/crontabs/www-data && \
    rm -rf /usr/bin/qemu-*-static

ENTRYPOINT ["/run_addon.sh"]
