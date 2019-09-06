ARG ARCH
ARG QEMUTAG

FROM multiarch/debian-debootstrap:${QEMUTAG}-stretch AS qemu
FROM ${ARCH}/nextcloud:apache

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin

RUN apt-get update && apt-get install -y supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY cronjobs         /var/spool/cron/crontabs/www-data

CMD ["/usr/bin/supervisord"]
