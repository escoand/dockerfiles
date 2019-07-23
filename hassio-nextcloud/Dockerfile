ARG BUILD_FROM
FROM $BUILD_FROM

COPY run_addon.sh /

RUN sed -i 's|/var/www/html|/data/nextcloud|g' /entrypoint.sh && \
    sed -i 's|/var/www/html|/data/nextcloud|g' /var/spool/cron/crontabs/www-data

ENTRYPOINT ["/run_addon.sh"]
