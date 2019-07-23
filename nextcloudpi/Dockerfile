ARG ARCH
ARG PHPVER=7.3

FROM ownyourbits/nextcloud-${ARCH}

# installation of dlib and pdlib
# https://github.com/matiasdelellis/facerecognition/wiki/Installation

RUN \
  echo 'deb [trusted=yes] https://packages.sury.org/php/ stretch main' >/etc/apt/sources.list.d/php.list && \
    echo 'Acquire::https::packages.sury.org::Verify-Peer "false";' >/etc/apt/apt.conf.d/ssl.conf && \
    echo 'Acquire::https::packages.sury.org::Verify-Host "false";' >>/etc/apt/apt.conf.d/ssl.conf && \
    apt-get update && \
    apt-get install --no-install-recommends -y build-essential cmake git liblapack-dev libopenblas-dev libx11-dev php${PHPVER}-dev pkg-config && \
  git -c http.sslVerify=false clone https://github.com/davisking/dlib.git && \
    cd dlib/dlib && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    make install && \
    cd && \
  git -c http.sslVerify=false clone https://github.com/goodspb/pdlib.git && \
    cd pdlib && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    find /etc/php/ && \
    ls /etc/php/${PHPVER}/*/php.ini | while read F; do echo '\n[pdlib]\nextension="pdlib.so"\n' >> $F; done && \
    cd && \
  apt-get purge -y build-essential cmake git liblapack-dev libopenblas-dev libx11-dev php${PHPVER}-dev pkg-config && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf dlib pdlib && \
    rm -rf /usr/share/man/* && \
    rm -rf /usr/share/doc/* && \
    rm -f /var/log/alternatives.log /var/log/apt/* && \
    rm /var/cache/debconf/*-old
