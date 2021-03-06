#
# - Base nginx
#
FROM ubuntu:14.04

#
# Prepare the container
#
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
ENV NGINX_VERSION 1.11.3
RUN echo "NGINX version = ${NGINX_VERSION}"
ENV DOCKERIZE_VERSION 0.2.0
ARG PHP_VERSION
ENV PHP_VERSION 7.0.9
RUN echo "PHP version = ${PHP_VERSION}"
ENV PHP_LIB redis-3.0.0 yaml-2.0.0RC8 amqp-1.7.1 memcached-2.2.0 apcu-5.1.5 v8js-1.3.1
ENV PHALCON_VER 3.0.0

ENV NGINX_EXTRA_CONFIGURE_ARGS \
        --sbin-path=/usr/sbin \
        --conf-path=/etc/nginx/nginx.conf \
        --with-md5=/usr/lib \
        --with-sha1=/usr/lib \
        --with-http_ssl_module \
        --with-http_dav_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module

ENV NGINX_BUILD_DEPS \
        bzip2 \
        file \
        libbz2-dev \
        libcurl4-openssl-dev \
        libmcrypt-dev \
#       libreadline6-dev \
        openssl \
        libssl-dev \
        libxslt1-dev \
        libxml2-dev \
        libpcre3 \
        libpcre3-dev \
        curl \
        libc6

ENV NGINX_EXTRA_BUILD_DEPS \
        gcc \
        libc-dev \
        make \
        pkg-config \
        libxml2 \
        ca-certificates \
        autoconf \
        runit \
        nano \
        less \
        tmux \
        wget \
        git

ENV PHP_BUILD_DEPS \
#       bzip2 \
#       file \
#       libbz2-dev \
#       libcurl4-openssl-dev \
#       libjpeg-dev \
#       libmcrypt-dev \
#       libpng12-dev \
#       libreadline6-dev \
#       libssl-dev \
#       libxslt1-dev \
#       libxml2-dev \
        mysql-client \
        libmysqlclient-dev\
        libyaml-dev \
        librabbitmq-dev \
        libsasl2-dev \
        libicu-dev

ENV PHP_EXTRA_BUILD_DEPS \
        re2c \
        g++ \
        python-software-properties \
        software-properties-common

ENV PHP_INI_DIR /etc/php

ENV PHP_EXTRA_CONFIGURE_ARGS \
        --sysconfdir=${PHP_INI_DIR} \
        --with-config-file-path=${PHP_INI_DIR} \
        --with-config-file-scan-dir=${PHP_INI_DIR}/conf.d \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --with-libdir=lib64 \
        --with-openssl \
        --with-php-config \
        --with-curl \
        --with-iconv \
        --with-pdo-mysql \
#       --with-curl \
        --with-mcrypt \
        --with-openssl \
        --with-xsl \
        --with-zlib \
        --enable-fpm \
        --enable-opcache \
        --enable-sockets \
        --enable-bcmath \
        --enable-mbstring \
        --enable-intl \
        --enable-mysqlnd \
#       --with-gd \
#       --with-mysql \
#       --with-mysqli \
#       --with-bz2 \
#       --with-gd \
#       --with-jpeg-dir \
#       --with-mysqli \
#       --with-pdo-mysql \
#       --with-readline \
#       --enable-pcntl \
#       --enable-gd-native-ttf \
#       --enable-calendar \
#       --enable-zip \
        --without-sqlite3 \
        --without-pdo-sqlite \
        --enable-tokenizer \
#       --disable-tokenizer \
        --disable-cgi \
        --disable-short-tags \
        --disable-fileinfo \
        --disable-posix

RUN sed -i 's/archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list

# Install nginx
RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NGINX_BUILD_DEPS} ${NGINX_EXTRA_BUILD_DEPS} \
    && rm -rf /var/lib/apt/lists/* \
    && gpg --keyserver pgpkeys.mit.edu --recv-key A1C052F8 \
    && mkdir -p /var/log/nginx \
    && set -x \
    && curl -SL "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.bz2 \
    && curl -SL "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc" -o nginx.tar.bz2.asc \
    && gpg --verify nginx.tar.bz2.asc \
    && mkdir -p /usr/src/nginx \
    && tar -xof nginx.tar.bz2 -C /usr/src/nginx --strip-components=1 \
    && rm nginx.tar.bz2* \
    && cd /usr/src/nginx \
    && ./configure ${NGINX_EXTRA_CONFIGURE_ARGS} \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && make clean
#   && apt-get purge --yes --force-yes --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $NGINX_EXTRA_BUILD_DEPS

RUN userdel www-data && groupadd -r www-data -g 433 && \
    mkdir /home/www-data && \
    mkdir -p /var/www && \
    useradd -u 431 -r -g www-data -d /home/www-data -s /sbin/nologin -c "Docker image user for web application" www-data && \
    chown -R www-data:www-data /home/www-data /var/www && \
    chmod 700 /home/www-data && \
    chmod 711 /var/www && \
    mkdir -p /etc/nginx/conf.d/

# Install php
RUN apt-get update && apt-get install -y --no-install-recommends \
    ${PHP_BUILD_DEPS} ${PHP_EXTRA_BUILD_DEPS} \
    && rm -r /var/lib/apt/lists/*

ENV PHP7_KEY "1A4E8B7277C42E53DBA9C7B9BCAA30EA9C0D5763 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3"
ENV PHP5_KEY "6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3 0BD78B5F97500D450838F95DFE857D9A90D90EC1"
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys ${PHP7_KEY} \
    && mkdir -p ${PHP_INI_DIR}/conf.d \
    && set -x \
    && curl -SL "http://php.net/get/php-${PHP_VERSION}.tar.bz2/from/this/mirror" -o php.tar.bz2 \
    && curl -SL "http://php.net/get/php-${PHP_VERSION}.tar.bz2.asc/from/this/mirror" -o php.tar.bz2.asc \
    && gpg --verify php.tar.bz2.asc \
    && mkdir -p /usr/src/php \
    && tar -xof php.tar.bz2 -C /usr/src/php --strip-components=1 \
    && rm php.tar.bz2* \
    && cd /usr/src/php \
    && ./configure ${PHP_EXTRA_CONFIGURE_ARGS} \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
    && make clean

RUN cp /usr/src/php/php.ini-production ${PHP_INI_DIR}/php.ini

RUN mkdir -p /usr/src/pecl && cd /usr/src/pecl \
    && wget https://github.com/phalcon/cphalcon/archive/v${PHALCON_VER}.tar.gz \
    && tar zxvf v${PHALCON_VER}.tar.gz && cd /usr/src/pecl/cphalcon-${PHALCON_VER}/build \
    && ./install \
    && echo "extension=phalcon.so" > ${PHP_INI_DIR}/conf.d/phalcon.ini \
    && wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz \
    && tar xzf libmemcached-1.0.18.tar.gz \
    && cd libmemcached-1.0.18 \
    && ./configure --enable-sasl \
    && make -j"$(nproc)" \
    && make install \
    && wget http://ftp.daum.net/ubuntu/pool/universe/libr/librabbitmq/librabbitmq4_0.8.0-1_amd64.deb \
    && dpkg -i librabbitmq4_0.8.0-1_amd64.deb \
    && wget http://ftp.daum.net/ubuntu/pool/universe/libr/librabbitmq/librabbitmq-dev_0.8.0-1_amd64.deb \
    && dpkg -i librabbitmq-dev_0.8.0-1_amd64.deb \
    && rm -rf *.deb libmemcached-1.0.18* \
    && rm -rf /usr/src/pecl/*

RUN pecl install xdebug \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so" > ${PHP_INI_DIR}/conf.d/xdebug.ini

RUN apt-add-repository ppa:pinepain/libv8-5.2 -y \
    && apt-get update \
    && apt-get install libv8-5.2-dev -y --allow-unauthenticated

# Install dockerize
RUN wget https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
    && rm -f /dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz

# Install composer
RUN bash -c "wget http://getcomposer.org/composer.phar && chmod +x composer.phar && mv composer.phar /usr/local/bin/composer"

# Install PHPUnit
RUN bash -c "wget https://phar.phpunit.de/phpunit.phar && chmod +x phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit"

COPY files /

RUN bash -c "/usr/local/bin/docker-pecl-install ${PHP_LIB}" && rm -rf /usr/src/pecl/*

VOLUME ["/var/www", "/etc/nginx", "/etc/php"]

EXPOSE 80
EXPOSE 443
EXPOSE 9000

CMD ["/run.sh"]
