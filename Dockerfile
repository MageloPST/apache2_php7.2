FROM ubuntu:18.04

ARG MYSQL=false
ARG PGSQL=false

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        apache2 \
        build-essential \
        ca-certificates \
        php7.2 \
        php7.2-bcmath \
        php7.2-mbstring \
        php7.2-xml \
        php7.2-gd \
        php7.2-cli \
        php7.2-curl \
        php7.2-fpm \
        libapache2-mod-php7.2

RUN if [ "$MYSQL" = false ]; then \
        echo 'Skipping mysql configuration'; \
    else \
        apt-get install -y --no-install-recommends \
            php7.2-mysql; \
    fi

RUN if [ "$PGSQL" = false ]; then \
        echo 'Skipping pgsql configuration'; \
    else \
        apt-get install -y --no-install-recommends \
            php7.2-pgsql; \
    fi

#### Install Apache configuration
COPY /configuration/001-default.conf /etc/apache2/sites-available/
ADD /configuration/apache2foreground /usr/local/bin/apache2foreground
ADD /configuration/phpfpm_start /usr/local/bin/phpfpm_start
ADD /configuration/apache2.conf /etc/apache2/apache2.conf

#### Provide clean directories for the child images
RUN chmod 774 /etc/apache2/apache2.conf && \
    a2dismod php7.2 && \
    a2dismod mpm_prefork && \
    a2enmod rewrite && \
    a2enmod ssl && \
    a2enmod http2 && \
    a2enmod deflate && \
    a2enmod proxy_fcgi && \
    a2enmod mpm_event && \
    a2enconf php7.2-fpm && \
    a2enmod headers && \
    a2enmod expires && \
    phpenmod opcache pdo calendar ctype exif fileinfo ftp gettext iconv \
    json phar posix readline shmop sockets sysvmsg sysvsem sysvshm tokenizer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/www/html/* /etc/apache2/sites-enabled/* && \
    rm -rf /etc/apache2/sites-enabled/*

RUN a2ensite 001-default.conf

WORKDIR /var/www/html
EXPOSE 80
CMD /usr/local/bin/apache2foreground
