FROM docker.io/php:8.5.9-apache

RUN apt update -y && \
    apt install -y libapache2-mod-auth-openidc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli