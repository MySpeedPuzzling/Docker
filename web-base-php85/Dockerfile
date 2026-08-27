FROM dunglas/frankenphp:php8.5-bookworm

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_HOME="/.composer" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
    PHP_ZEND_ASSERTIONS=1 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=192 \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE=10 \
    SERVER_NAME=:8080 \
    FRANKENPHP_WORKER="" \
    FRANKENPHP_WORKER_FILE="/app/public/index.php" \
    FRANKENPHP_WORKER_NUM="" \
    FRANKENPHP_WATCH="" \
    FRANKENPHP_WATCH_PATHS="./src/**/*.php ./config/**/*.{yaml,yml} ./templates/**/*.twig" \
    FRANKENPHP_CONFIG="" \
    FRANKENPHP_MAX_WAIT_TIME="" \
    FRANKENPHP_MAX_REQUESTS=""

COPY bin/wait-for-it.sh /usr/local/bin/wait-for-it

# Very convenient PHP extensions installer: https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Layer 1: System dependencies
RUN chmod +x /usr/local/bin/wait-for-it \
    && mkdir -p /.composer /usr/tmp /docker-entrypoint.d /etc/frankenphp/Caddyfile.d /data \
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
        brotli \
        zstd \
    && apt-get remove -y libheif1 \
    && apt-get update && apt-get install -y \
        inkscape \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Build libheif with AVIF support
RUN cd /usr/local/src \
    && git clone --branch v1.20.2 https://github.com/strukturag/libheif.git \
    && cd libheif \
    && mkdir build \
    && cd build \
    && cmake -DENABLE_AVIF=ON .. \
    && make && make install \
    && ldconfig \
    && rm -rf /usr/local/src/libheif

# Layer 3: PHP extensions
RUN install-php-extensions \
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
        xdebug

# Xdebug stays installed but ships disabled: the entrypoint enables it only
# when XDEBUG_MODE is set (dev compose does). Merely loading the extension
# costs significant performance, so no derived image can run it by accident.
RUN mv "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini.disabled"

# Layer 4: Node.js and Sentry CLI
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && curl -sL https://sentry.io/get-cli/ | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# The imagick install above apt-reinstalls Debian's libheif1 (removed in
# layer 1), and its file wins SONAME resolution over /usr/local/lib, leaving
# the custom v1.20.2 AVIF build unused. Divert the distro files out of the
# linker's search path and assert the ImageMagick heic coder now resolves
# the custom build.
RUN set -eux; \
    mkdir -p /usr/lib/diverted-libheif; \
    for f in /usr/lib/*-linux-gnu/libheif.so.1*; do \
        dpkg-divert --divert "/usr/lib/diverted-libheif/$(basename "$f")" --rename "$f"; \
    done; \
    ldconfig; \
    coder="$(find /usr/lib -path '*coders*' -name 'heic.so' | head -1)"; \
    ldd "$coder" | grep -q '/usr/local/lib/libheif.so.1'

COPY imagemagick-policy.xml /etc/ImageMagick-6/policy.xml
COPY Caddyfile /etc/caddy/Caddyfile

WORKDIR /app

COPY php.ini /usr/local/etc/php/conf.d/99-php-overrides.ini

COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
