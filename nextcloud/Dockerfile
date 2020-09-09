FROM nextcloud:apache as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        libopenblas-dev \
        libx11-dev \
        wget

ARG DLIB_BRANCH=v19.19
RUN wget -c -q https://github.com/davisking/dlib/archive/$DLIB_BRANCH.tar.gz \
    && tar xf $DLIB_BRANCH.tar.gz \
    && mv dlib-* dlib \
    && cd dlib/dlib \
    && mkdir build \
    && cd build \
    && cmake -DBUILD_SHARED_LIBS=ON --config Release .. \
    && make \
    && make install

ARG PDLIB_BRANCH=master
RUN apt-get install -y --no-install-recommends \
        unzip \
    && wget -c -q https://github.com/matiasdelellis/pdlib/archive/$PDLIB_BRANCH.zip \
    && unzip $PDLIB_BRANCH \
    && mv pdlib-* pdlib \
    && cd pdlib \
    && phpize \
    && ./configure \
    && make \
    && make install

# RUN php -i | grep "Scan this dir for additional .ini files"
RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini \
    && apt-get install -y --no-install-recommends \
        git \
    && git clone https://github.com/matiasdelellis/pdlib-min-test-suite.git \
    && cd pdlib-min-test-suite \
    && make

# build final image
FROM nextcloud:apache

RUN mkdir -p /usr/share/man/man1 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        default-jre-headless \
        libbz2-dev \
        libopenblas-base \
    && docker-php-ext-install bz2

#RUN php -i | grep extension_dir
COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20190902/pdlib.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini \
    && echo "memory_limit=1G" > /usr/local/etc/php/conf.d/memory-limit.ini

# workout converter
COPY workout2svg.* /usr/local/bin/
RUN mkdir -p /usr/local/java \
    && wget -O /tmp/saxon.zip http://www.saxonica.com/download/SaxonEE10-1J.zip \
    && unzip /tmp/saxon.zip "saxon-ee-1*" -d /usr/local/java/ \
    && rm /tmp/saxon.zip

# cronjobs
COPY cron.www-data /tmp/
RUN cat /tmp/cron.www-data >> /var/spool/cron/crontabs/www-data \
    && rm /tmp/cron.www-data
