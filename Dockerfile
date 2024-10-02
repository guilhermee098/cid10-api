FROM php:5.6-apache

# Atualizar sources.list para usar archive.debian.org e remover stretch-updates
RUN sed -i 's/deb.debian.org\/debian/archive.debian.org\/debian/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid-until

# Instalar dependências adicionais
RUN apt-get update && apt-get install -y \
    curl \
    git \
    libxml2-dev \
    libcurl4-openssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libicu-dev \
    locales \
    unzip \
    && docker-php-ext-install zip

# Configurar locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Instalar extensões PHP necessárias
RUN docker-php-ext-install mbstring xmlrpc xml dom json

# Configurar PHP
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i.bak 's/upload_max_filesize = .*/upload_max_filesize = 15M/g' /usr/local/etc/php/php.ini && \
    sed -i.bak 's/post_max_size = .*/post_max_size = 15M/g' /usr/local/etc/php/php.ini && \
    sed -i.bak 's/;date.timezone =.*/date.timezone = America\/Sao_Paulo/g' /usr/local/etc/php/php.ini && \
    sed -i.bak 's/short_open_tag = .*/short_open_tag = On/g' /usr/local/etc/php/php.ini

# Habilitar módulos do Apache
RUN a2enmod headers \
            actions \
            rewrite \
            expires \
            deflate

# Configurar ServerName
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Adicionar configuração do Virtual Host
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configurar usuário 'deployer'
RUN groupadd -g 1000 deployer && \
    useradd -u 1000 -g deployer -m deployer && \
    chown -R deployer:deployer /var/www/html && \
    sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=deployer/' /etc/apache2/envvars && \
    sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=deployer/' /etc/apache2/envvars

# Copiar código da aplicação
COPY --chown=deployer:deployer . /var/www/html

# Definir diretório de trabalho
WORKDIR /var/www/html

# Instalar dependências do Composer
USER deployer
RUN composer install

# Retornar ao usuário root
USER root

# Expor a porta 80
EXPOSE 80

# Comando para iniciar o Apache em primeiro plano
CMD ["apache2-foreground"]
