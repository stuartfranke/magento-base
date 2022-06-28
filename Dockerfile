FROM php:7.4.19-fpm-alpine3.12

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV USER_DIRECTORY "/root"
ENV NGINX_GROUP "www-data"
ENV NGINX_USER "www-data"
ENV WEB_ROOT "/www"

RUN apk update --progress --purge \
    # Install required packages
    # @todo version lock packages
    && apk add --latest --progress --purge \
        autoconf \
        curl \
        dos2unix \
        freetype-dev \
        g++ \
        gcc \
        git \
        gnupg \
        gzip \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libxslt-dev \
        libzip-dev \
        lsof \
        make \
        sed \
        tar \
        unzip \
        vim \
        wget \
    # Install PHP extensions @todo 1. version lock extensions 2. move dev specific extensions to dev environment
    && docker-php-ext-install \
        bcmath \
        intl \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && pecl install \
        xdebug-2.9.6 \
        apcu \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install gd \
    && docker-php-ext-enable \
        apcu \
        xdebug

# Copy PHP config files
COPY ./docker/app/etc/conf.d/* /usr/local/etc/php/conf.d
COPY ./docker/app/etc/php.ini /usr/local/etc/php

# Create Xdebug log file
# @todo find a way to not give full access to the log file
# @todo move this to dev environment installer
RUN touch /var/log/xdebug.log \
    && chmod 777 /var/log/xdebug.log

# Install Composer
# @todo find a way to not use Composer globally
# @todo move to dev environment installer
COPY ./docker/app/scripts/composer-installer.sh ${USER_DIRECTORY}/composer-installer

RUN chmod +x ${USER_DIRECTORY}/composer-installer \
    && dos2unix ${USER_DIRECTORY}/composer-installer \
    && ${USER_DIRECTORY}/composer-installer \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && echo "{}" > ${USER_DIRECTORY}/.composer/composer.json \
    && rm ${USER_DIRECTORY}/composer-installer

# Install Node / NPM / Yarn
# @todo rather use the Node service or move to dev environment installer
COPY ./docker/app/scripts/node-installer.sh ${USER_DIRECTORY}/node-installer

RUN chmod +x ${USER_DIRECTORY}/node-installer \
    && dos2unix ${USER_DIRECTORY}/node-installer \
    && ${USER_DIRECTORY}/node-installer \
    && rm ${USER_DIRECTORY}/node-installer

# Copy project files
COPY --chown=${NGINX_USER}:${NGINX_GROUP} . ${WEB_ROOT}/

WORKDIR ${WEB_ROOT}
