FROM nextcloud:apache as builder

RUN apt-get update \
    && apt-get install -y \
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
RUN apt-get install unzip \
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
    && apt-get install -y git \
    && git clone https://github.com/matiasdelellis/pdlib-min-test-suite.git \
    && cd pdlib-min-test-suite \
    && make

FROM nextcloud:apache

RUN apt-get update \
    && apt-get install -y libopenblas-base libbz2-dev \
    && docker-php-ext-install bz2

#RUN php -i | grep extension_dir
COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20190902/pdlib.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini \
    && echo "memory_limit=-1" > /usr/local/etc/php/conf.d/memory-limit.ini
