FROM justckr/ubuntu-nginx:latest

MAINTAINER Constantinos Kouloumbris <c@kouloumbris.com>

# Xdebug Remote Host IP
ENV XDEBUG_REMOTE_HOST_IP 192.168.65.1

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

RUN apt-get install -y software-properties-common \
    python-software-properties \
    language-pack-en-base

RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y php7.0-fpm \
    php7.0-mysql \
    php7.0-curl \
    php7.0-gd \
    php7.0-intl \
    php7.0-mcrypt \
    php-memcache \
    php7.0-sqlite \
    php7.0-tidy \
    php7.0-xmlrpc \
    php7.0-pgsql \
    php7.0-ldap \
    freetds-common \
    php7.0-pgsql \
    php7.0-sqlite3 \
    php7.0-json \
    php7.0-xml \
    php7.0-mbstring \
    php7.0-soap \
    php7.0-zip \
    php7.0-cli \
    php7.0-sybase \
    php7.0-odbc \
    php7.0-dev

# Install xdebug
RUN wget http://xdebug.org/files/xdebug-2.4.0.tgz
RUN tar -xvzf xdebug-2.4.0.tgz
RUN cd xdebug-2.4.0 && phpize
RUN cd xdebug-2.4.0 && ./configure
RUN cd xdebug-2.4.0 && make
RUN cd xdebug-2.4.0 && cp modules/xdebug.so /usr/lib/php/20131226
ADD conf/xdebug.conf /xdebug.conf
RUN cat /xdebug.conf >> /etc/php/7.0/fpm/php.ini
RUN rm -rf /xdebug-2.4.0
RUN rm -rf /xdebug-2.4.0.tgz

# Cleanup
RUN apt-get remove --purge -y software-properties-common \
    python-software-properties

RUN apt-get autoremove -y
RUN apt-get clean
RUN apt-get autoclean

#tweek php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "/listen\s*=\s*\/run\/php\/php7.0-fpm.sock/c\listen = 127.0.0.1:9100" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "/pid\s*=\s*\/run/c\pid = /run/php7.0-fpm.pid" /etc/php/7.0/fpm/php-fpm.conf

#fix ownership of sock file
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Supervisor Config
ADD conf/supervisord.conf /supervisord.conf
RUN cat /supervisord.conf >> /etc/supervisord.conf

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Setup Volume
VOLUME ["/app"]

# add test PHP file
# ADD src/index.php /app/src/public/index.php
# ADD src/index.php /app/src/public/info.php
RUN chown -Rf www-data.www-data /app
RUN chown -Rf www-data.www-data /var/www/html



# Expose Ports
EXPOSE 443
EXPOSE 80
EXPOSE 9000

#RUN apt-get install mc -y

# Install yii2
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN composer create-project --prefer-dist yiisoft/yii2-app-basic basic

# Config nginx for yii (change root folder)
RUN sed -i -e 's/^\t*root.*/root \/basic\/web;/' /etc/nginx/sites-available/default.conf
#RUN chmod -Rf www-data.www-data /basic/web

VOLUME ["/basic/web/"]
#ADD src/index.php /basic/web/info.php

#CMD ["mc"]

CMD ["/bin/bash", "/start.sh"]
