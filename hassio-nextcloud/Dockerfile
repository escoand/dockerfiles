ARG BUILD_FROM
FROM $BUILD_FROM

RUN sed -i 's|/var/www/html|/data/nextcloud|g' \
        /entrypoint.sh \
        /var/spool/cron/crontabs/www-data \
        /etc/apache2/sites-available/*.conf && \
    sed -i -n '/<Directory \/var\/www\/>/,/<\/Directory>/{s|/var/www/|/share/nextcloud/|;H;s|/share/nextcloud/|/data/nextcloud/|}; p; ${x;p}' \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-enabled/docker-php.conf && \
    apt-get update && \
    apt-get install --no-install-recommends -y jq supervisor && \
    mkdir /var/log/supervisord /var/run/supervisord && \
    rm -rf /var/lib/apt/lists/* /usr/bin/qemu-*-static

COPY run_addon.sh     /
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY cronjobs         /var/spool/cron/crontabs/www-data

ENTRYPOINT ["/run_addon.sh"]
CMD ["/usr/bin/supervisord"]
