FROM php:5.6-apache

# RUN find / ! -path "/proc/*" -user www-data -exec chown -h 1000 {} \;
# RUN find / ! -path "/proc/*" -group www-data -exec chgrp -h 1000 {} \;

# RUN usermod --uid 1000 www-data
# RUN groupmod --gid 1000 www-data
# RUN usermod --gid 1000 www-data

RUN apt-get update && apt-get install -y \
	bzip2 \
	libcurl4-openssl-dev \
	libfreetype6-dev \
	libicu-dev \
	libjpeg-dev \
	libmcrypt-dev \
	libmemcached-dev \
	libpng12-dev \
	libpq-dev \
	libxml2-dev \
	vim \
 	sudo \
	&& rm -rf /var/lib/apt/lists/*

#gpg key from https://owncloud.org/owncloud.asc
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys E3036906AD9F30807351FAC32D5D5E97F6978A26

# https://doc.owncloud.org/server/8.1/admin_manual/installation/source_installation.html#prerequisites
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd intl mbstring mcrypt mysql opcache pdo_mysql pdo_pgsql pgsql zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PECL extensions
RUN pecl install APCu-beta redis memcached \
	&& docker-php-ext-enable apcu redis memcached

# Fix SSL
RUN sed -i -e 's/\t\t\(.*${APACHE_LOG_DIR}.*\)/\t\t###\1/' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i -e 's!/etc/ssl/certs/ssl-cert-snakeoil.pem!/var/owncloud/ssl/apache.pem!' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i -e 's!/etc/ssl/private/ssl-cert-snakeoil.key!/var/owncloud/ssl/apache.key!' /etc/apache2/sites-available/default-ssl.conf

RUN a2enmod rewrite
RUN a2ensite default-ssl.conf
RUN a2enmod ssl

ENV OWNCLOUD_VERSION 8.2.0
VOLUME /var/www/html

RUN curl -fsSL -o owncloud.tar.bz2 \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2" \
	&& curl -fsSL -o owncloud.tar.bz2.asc \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2.asc" \
	&& gpg --verify owncloud.tar.bz2.asc \
	&& tar -xjf owncloud.tar.bz2 -C /usr/src/ \
	&& rm owncloud.tar.bz2 owncloud.tar.bz2.asc

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
