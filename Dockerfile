FROM phusion/baseimage
ENV PATH $PATH:/app/vendor/bin:/app:/app/node_modules/.bin
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV APP_ENV production

EXPOSE 80


ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["/usr/local/bin/bootstrap-web"]

RUN curl https://download.newrelic.com/548C16BF.gpg | apt-key add - \
    && curl -sL https://deb.nodesource.com/setup_9.x | bash - \
    && apt-add-repository -y ppa:ondrej/php \
    && echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -qqy --force-yes \
        git \
        php7.2-cli \
        php7.2-xdebug \
        php7.2-common \
        php7.2-fpm \
        php7.2-zip \
        php7.2-mbstring \
        php7.2-mysql \
        php7.2-imagick \
        php7.2-gd \
        php7.2-curl \
        php7.2-pgsql \
        php7.2-xml \
        php7.2-sqlite \
        php7.2-pgsql \
        php7.2-bcmath \
        newrelic-php5 \
        nginx \
        mysql-client \
        nodejs \
        libpng16-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY etc/.bashrc /root/.bashrc
COPY etc/composer-auth.json /root/.composer/auth.json
COPY etc/php.ini /etc/php/7.2/cli/php.ini
COPY etc/xdebug.ini /etc/php/7.2/mods-available/xdebug.ini
COPY etc/newrelic.ini /etc/php/7.2/mods-available/newrelic.ini
COPY etc/key.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

COPY etc/php.ini /etc/php/7.2/fpm/php.ini
COPY etc/php-fpm.conf /etc/php/7.2/fpm/php-fpm.conf
COPY etc/nginx.conf /etc/nginx/sites-available/default

COPY bin/* /usr/local/bin/

RUN rm -rf /etc/service/cron /etc/my_init.d/10_syslog-ng.init

RUN phpdismod -v 7.2 -s ALL xdebug newrelic
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local && mv /usr/local/composer.phar /usr/local/bin/composer

RUN mkdir /app
WORKDIR /app

ONBUILD COPY composer* package* /app/
ONBUILD RUN composer install --no-scripts --no-plugins --no-autoloader --no-dev && composer clear-cache
ONBUILD RUN npm install
ONBUILD COPY . /app
ONBUILD RUN composer -o dump-autoload
ONBUILD RUN artisan config:cache
ONBUILD RUN npm run production
