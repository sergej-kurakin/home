FROM php:5-alpine AS builder

RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini" \
    && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > "$PHP_INI_DIR/conf.d/date_timezone.ini"

RUN apk add --no-cache --virtual .persistent-deps \
                ca-certificates \
                wget \
                tar \
                xz \
                git \
                subversion \
                openssh \
                mercurial \
                tini \
                bash \
                patch \
                make

RUN apk add --no-cache --virtual .build-deps zlib-dev \
    && docker-php-ext-install zip

WORKDIR /var/www/html/

COPY Makefile /var/www/html/
COPY composer.json /var/www/html/
COPY composer.lock /var/www/html/
COPY .phrozn /var/www/html/.phrozn

RUN mkdir -p /var/www/html/public_html/

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.7.2

RUN wget -q https://getcomposer.org/download/1.7.2/composer.phar
RUN /usr/local/bin/php -f composer.phar install --quiet --no-dev --no-scripts --no-progress --no-suggest

RUN /usr/bin/make


# Run everything in nginx

FROM nginx:stable-alpine

RUN rm -rf /usr/share/nginx/html/ && mkdir -p /usr/share/nginx/html/

COPY --from=0 /var/www/html/public_html/ /usr/share/nginx/html/
