ARG QEMUTAG
ARG BUILD_FROM

FROM multiarch/debian-debootstrap:${QEMUTAG}-stretch AS qemu
FROM $BUILD_FROM

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin
COPY run_addon.sh /

RUN sed -i 's|/var/www/html|/data/nextcloud|g' \
        /entrypoint.sh /var/spool/cron/crontabs/www-data /etc/apache2/sites-available/*.conf && \
    apt-get update && \
    apt-get install --no-install-recommends -y jq && \
    rm -rf /var/lib/apt/lists/* /usr/bin/qemu-*-static

ENTRYPOINT ["/run_addon.sh"]
CMD ["/usr/bin/supervisord"]
