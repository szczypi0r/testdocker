FROM ubuntu:16.04
MAINTAINER Colin South <colinvsouth@gmail.com>

# Initialise

WORKDIR /root/development-environment
VOLUME ["/var/www"]

ENV DEBIAN_FRONTEND noninteractive

# Upgrade

RUN apt-get update && apt-get install -y apt-utils && apt-get dist-upgrade -y && apt-get install -y curl sudo git software-properties-common zsh htop locales wget

# Fetch payload

RUN git clone "https://github.com/cvsouth/apache-php7-mysql-redis.git" "/root/development-environment" && chmod 775 /root/development-environment/payload/*.sh && chmod +x /root/development-environment/payload/*.sh

# Time

RUN echo "Europe/London" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8; export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; locale-gen en_US.UTF-8; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# MySQL

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
RUN cp /root/development-environment/payload/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf && \
    echo "mysqld_safe --skip-networking &" > /tmp/config && \
    echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
    echo "mysqladmin password \"secret\"" >> /tmp/config && \
    echo "mysql -u root -p\"secret\" -e \"   GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION; FLUSH PRIVILEGES; \"" >> /tmp/config && \
    echo "killall mysqld_safe && service mysql start" >> /tmp/config && \
    bash /tmp/config && \
    rm -f /tmp/config

VOLUME ["/etc/mysql", "/var/lib/mysql"]
CMD ["mysqld_safe"]
EXPOSE 3306

# ffmpeg

RUN curl http://ffmpeg.gusari.org/static/64bit/ffmpeg.static.64bit.latest.tar.gz | tar xfvz - -C /usr/local/bin && apt-get install -y lame

# Apache PHP

RUN apt-get install -y \
    apache2 \
    apache2-utils \
    php7.0 \
    libapache2-mod-php7.0 \
    php7.0-mysql \
    php7.0-curl \
    php7.0-gd \
    php7.0-dev \
    php7.0-cli \
    php7.0-json \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-xsl \
    php7.0-zip \
    php7.0-xml \
    memcached \
    php-memcache \
    imagemagick \
    php-imagick

ENV APACHE_RUN_USER    www-data
ENV APACHE_RUN_GROUP   www-data
ENV APACHE_PID_FILE    /var/run/apache2.pid
ENV APACHE_RUN_DIR     /var/run/apache2
ENV APACHE_LOCK_DIR    /var/lock/apache2
ENV APACHE_LOG_DIR     /var/log/apache2
ENV LANG               C
RUN a2enmod php7.0 && a2enmod rewrite
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
RUN cp /root/development-environment/payload/apache.conf /etc/apache2/apache.conf
RUN cp /root/development-environment/payload/000-default.conf /etc/apache2/sites-available/000-default.conf
EXPOSE 80

# Composer

RUN curl -sS https://getcomposer.org/installer | php
RUN sudo mv composer.phar /usr/local/bin/composer

# NodeJS / NPM

RUN apt-get install -y nodejs npm && npm install gulp && ln -s /usr/bin/nodejs /usr/bin/node && npm install

# Redis

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv C7917B12 && \
    apt-key update && apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server # && \
    #apt-get clean && \
    #rm -rf /var/lib/apt/lists/*
RUN cp /root/development-environment/payload/redis.conf /etc/redis/redis.conf

# Xdebug

RUN wget http://xdebug.org/files/xdebug-2.4.1.tgz && \
    tar -xvzf xdebug-2.4.1.tgz && \
    cd xdebug-2.4.1 && \
    phpize && \
    ./configure && \
    make && \
    cp modules/xdebug.so /usr/lib/php/20151012 && \
    echo "" >> /etc/php/7.0/cli/php.ini && \
    echo "[xdebug]" >> /etc/php/7.0/cli/php.ini && \
    echo "zend_extension = /usr/lib/php/20151012/xdebug.so" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_enable=on" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_handler=dbgp" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_mode=req" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_host=localhost" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_connect_back=1" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.scream=0" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.remote_port=9000" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.show_local_vars=1" >> /etc/php/7.0/cli/php.ini && \
    echo "xdebug.idekey=PHPSTORM" >> /etc/php/7.0/cli/php.ini && \
    echo "" >> /etc/php/7.0/apache2/php.ini && \
    echo "[xdebug]" >> /etc/php/7.0/apache2/php.ini && \
    echo "zend_extension = /usr/lib/php/20151012/xdebug.so" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_enable=on" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_handler=dbgp" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_mode=req" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_host=localhost" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_connect_back=1" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.scream=0" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.remote_port=9000" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.show_local_vars=1" >> /etc/php/7.0/apache2/php.ini && \
    echo "xdebug.idekey=PHPSTORM" >> /etc/php/7.0/apache2/php.ini && \
    cd ..

# Run scripts

RUN sed -i -e 's/\r$//' "/root/development-environment/payload/init.sh"
CMD [ "/root/development-environment/payload/init.sh" ]







