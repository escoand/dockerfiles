FROM nextcloud:apache

RUN apt-get update && apt-get install -y supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY cronjobs         /var/spool/cron/crontabs/www-data

RUN apt-get update && \
    apt-get install --no-install-recommends -y cmake git liblapack-dev libopenblas-dev libx11-dev && \
    rm -rf /var/lib/apt/lists/*

# installation of dlib and pdlib
# https://github.com/matiasdelellis/facerecognition/wiki/Installation

RUN git clone https://github.com/davisking/dlib.git && \
    cd dlib/dlib && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    make install && \
    rm -rf ../../../dlib

RUN git clone https://github.com/goodspb/pdlib.git && \
    cd pdlib && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    find /etc/php/ && \
    ls /etc/php/${PHPVER}/*/php.ini | while read F; do echo '\n[pdlib]\nextension="pdlib.so"\n' >> $F; done && \
    rm -rf ../pdlib

RUN apt-get purge -y cmake git liblapack-dev libopenblas-dev libx11-dev && \
    apt-get autoremove && \
    apt-get clean

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord"]
