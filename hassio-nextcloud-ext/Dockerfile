ARG QEMUTAG
ARG BUILD_FROM

FROM multiarch/debian-debootstrap:${QEMUTAG}-stretch AS qemu
FROM $BUILD_FROM

COPY --from=qemu /usr/bin/qemu-*-static /usr/bin

# installation of dlib and pdlib
# https://github.com/matiasdelellis/facerecognition/wiki/Installation

RUN apt-get update && \
    apt-get install --no-install-recommends -y cmake git liblapack3 liblapack-dev libopenblas-base libopenblas-dev libx11-dev supervisor && \
    git clone https://github.com/davisking/dlib.git /tmp/dlib && \
    mkdir /tmp/dlib/dlib/build && \
    cd /tmp/dlib/dlib/build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    make install && \
    git clone https://github.com/goodspb/pdlib.git /usr/src/php/ext/pdlib && \
    docker-php-ext-install pdlib && \
    apt-get purge -y cmake git liblapack-dev libopenblas-dev libx11-dev && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /tmp/dlib /usr/src/php/ext/pdlib /var/lib/apt/lists/* && \
    rm -rf /usr/bin/qemu-*-static && \
    mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY cronjobs         /var/spool/cron/crontabs/www-data

CMD ["/usr/bin/supervisord"]
