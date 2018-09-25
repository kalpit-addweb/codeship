FROM php:7.2-fpm

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
		mbstring \
		pdo \
		zip \
	  bcmath \
	  mysqli \
	  sockets \
	  bcmath \
	  exif \
	  tokenizer \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=1'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini


RUN apt-get update
RUN apt-get install -y \
   git \
   vim \
   cron \
   zip \
   unzip \
   nano \
   libmemcached-dev \
   curl \
   mysql-client \
   sendmail-bin \
   sendmail \
   wget \
   sudo \
   bash-completion \
   apt-utils \
   gnupg \ 
   gnupg2 \
   gnupg1 

RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
RUN curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Install composer
RUN curl -sSL https://getcomposer.org/installer | php  && \
   mv composer.phar /usr/local/bin/composer &&\

   # Install PHPUnit
  curl -sSL https://phar.phpunit.de/phpunit.phar -o phpunit.phar && \
    chmod +x phpunit.phar && \
       mv phpunit.phar /usr/local/bin/phpunit && \

    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> /root/.bashrc
RUN composer global require "hirak/prestissimo:^0.3"
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN sudo apt-get install -y nodejs
WORKDIR /var/www/html

