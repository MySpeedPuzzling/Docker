FROM dunglas/frankenphp:php8.5-bookworm

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_HOME="/.composer" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=15000 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=192 \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE=10 \
    SERVER_NAME=:8080 \
    FRANKENPHP_WORKER="" \
    FRANKENPHP_WORKER_FILE="/app/public/index.php" \
    FRANKENPHP_WORKER_NUM="" \
    FRANKENPHP_WATCH="" \
    FRANKENPHP_WATCH_PATHS="./src/**/*.php ./config/**/*.{yaml,yml} ./templates/**/*.twig" \
    FRANKENPHP_CONFIG=""

COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY bin/wait-for-it.sh /usr/local/bin/wait-for-it

# Very convenient PHP extensions installer: https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/wait-for-it \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /.composer \
    && mkdir -p /usr/tmp \
    && mkdir -p /docker-entrypoint.d \
    && mkdir -p /etc/frankenphp/Caddyfile.d \
    && apt-get update && apt-get install -y \
        build-essential \
        cmake \
        git \
        zip \
        ca-certificates \
        curl \
        lsb-release \
        gnupg \
        wget \
        nano \
        wkhtmltopdf \
        libmagickwand-dev \
        libde265-dev \
        libx265-dev \
        libaom-dev \
        libdav1d-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        pkg-config \
        librsvg2-bin \
    && apt-get remove -y libheif1 \
    && apt-get update && apt-get install -y \
        inkscape \
    && cd /usr/local/src && \
        git clone --branch v1.20.2 https://github.com/strukturag/libheif.git && \
        cd libheif && \
        mkdir build && \
        cd build && \
        cmake -DENABLE_AVIF=ON .. && \
        make && make install && \
        ldconfig && \
        rm -rf /usr/local/src/libheif \
    && install-php-extensions \
        @composer \
        bcmath \
        intl \
        pcntl \
        zip \
        uuid \
        pdo_pgsql \
        opcache \
        apcu \
        gd \
        exif \
        redis \
        excimer \
        xsl \
        imagick \
        xdebug \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Caddyfile /etc/caddy/Caddyfile

WORKDIR /app

COPY php.ini /usr/local/etc/php/conf.d/99-php-overrides.ini

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
