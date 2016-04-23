FROM owncloud:9.0.1

RUN apt-get update && apt-get install -y \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Fix SSL
RUN sed -i -e 's/\t\t\(.*${APACHE_LOG_DIR}.*\)/\t\t###\1/' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i -e 's!/etc/ssl/certs/ssl-cert-snakeoil.pem!/var/owncloud/ssl/apache.pem!' /etc/apache2/sites-available/default-ssl.conf
RUN sed -i -e 's!/etc/ssl/private/ssl-cert-snakeoil.key!/var/owncloud/ssl/apache.key!' /etc/apache2/sites-available/default-ssl.conf

RUN a2enmod rewrite
RUN a2ensite default-ssl.conf
RUN a2enmod ssl

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
