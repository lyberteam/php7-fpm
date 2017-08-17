FROM php:7.0.9-fpm

ADD lyberteam-message.sh /var/www/lyberteam/lyberteam-message.sh
RUN chmod +x /var/www/lyberteam/lyberteam-message.sh
RUN /var/www/lyberteam/lyberteam-message.sh && rm -f /var/www/lyberteam/lyberteam-message.sh


MAINTAINER Lyberteam <lyberteamltd@gmail.com>
LABEL Vendor="Lyberteam"
LABEL Description="PHP-FPM v7.0.9-fpm"
LABEL Version="v7.0.9"

RUN apt-get update && apt-get install -y \
        libicu-dev \
        libpq-dev \
        libbz2-dev \
        php-pear \
        mc \
        vim \
        wget \
        cron \
        libevent-dev \
        librabbitmq-dev \
        libxml2 \
        libxslt-dev \
    && docker-php-ext-install xsl \
    && docker-php-ext-install iconv \
    && docker-php-ext-install zip \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install intl \
    && docker-php-ext-install pgsql pdo pdo_pgsql \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install opcache \
    && docker-php-ext-enable opcache \
    && apt-get install -y -q --no-install-recommends \
       ssmtp

# Install mcrypt
RUN apt-get install -y libmcrypt-dev
RUN docker-php-ext-install mcrypt

# Install GD
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev \
    && docker-php-ext-configure gd \
          --enable-gd-native-ttf \
          --with-freetype-dir=/usr/include/freetype2 \
          --with-png-dir=/usr/include \
          --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd \
    && docker-php-ext-enable gd

# Install Imagick
RUN apt-get install -y \
       libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick

## Install Xdebug
RUN curl -fsSL 'https://xdebug.org/files/xdebug-2.5.3.tgz' -o xdebug.tar.gz \
    && mkdir -p xdebug \
    && tar -xf xdebug.tar.gz -C xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && ( \
        cd xdebug \
        && phpize \
        && ./configure --enable-xdebug \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r xdebug \
    && docker-php-ext-enable xdebug


ADD xdebug.ini /usr/local/etc/php/conf.d/

# Change TimeZone
RUN echo "Set default timezone - Europe/Kiev"
RUN echo "Europe/Kiev" > /etc/timezone

# Install composer globally
RUN echo "Install composer globally"
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

COPY php.ini /usr/local/etc/php/

RUN /bin/bash -c 'rm -f /usr/local/etc/php-fpm.d/www.conf.default'
ADD symfony.pool.conf /usr/local/etc/php-fpm.d/
RUN rm -f /usr/local/etc/php-fpm.d/www.conf


RUN usermod -u 1000 www-data

CMD ["php-fpm"]

## Let's set the working dir
WORKDIR /var/www/lyberteam

EXPOSE 9000

RUN  dpkg-reconfigure -f noninteractive tzdata
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
