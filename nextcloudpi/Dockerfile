ARG ARCH

FROM ownyourbits/nextcloud-${ARCH}

# installation of dlib and pdlib
# https://github.com/matiasdelellis/facerecognition/wiki/Installation

RUN \
  echo 'deb [trusted=yes] https://packages.sury.org/php/ stretch main' >/etc/apt/sources.list.d/php.list && \
    echo 'Acquire::https::packages.sury.org::Verify-Peer "false";' >/etc/apt/apt.conf.d/ssl.conf && \
    echo 'Acquire::https::packages.sury.org::Verify-Host "false";' >>/etc/apt/apt.conf.d/ssl.conf && \
    apt-get update && \
    apt-get install --no-install-recommends -y build-essential cmake git liblapack-dev libopenblas-dev libx11-dev php7.3-dev pkg-config && \
  git -c http.sslVerify=false clone https://github.com/davisking/dlib.git && \
    cd dlib/dlib && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make && \
    make install && \
  git -c http.sslVerify=false clone https://github.com/goodspb/pdlib.git && \
    cd pdlib && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    echo '\n[pdlib]\nextension="pdlib.so"\n' >>/etc/php/7.3/cli/php.ini && \
    echo '\n[pdlib]\nextension="pdlib.so"\n' >>/etc/php/7.3/fpm/php.ini && \
  apt-get autoremove -y build-essential cmake git liblapack-dev libopenblas-dev libx11-dev php7.3-dev pkg-config && \
    apt-get clean && \
    rm -rf dlib pdlib && \
    rm -rf /usr/share/man/* && \
    rm -rf /usr/share/doc/* && \
    rm -f /var/log/alternatives.log /var/log/apt/* && \
    rm /var/cache/debconf/*-old
