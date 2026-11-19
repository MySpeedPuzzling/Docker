# libheif 1.20.2 with AVIF support, compiled in its own stage: the compiler
# toolchain, cmake and every -dev package it needs stay here, only the
# `make install` output is copied into the final image. libmagickwand-dev is
# installed for the -dev libraries it pulls in (tiff, gdk-pixbuf, ...), so
# libheif's cmake detects the same set as before and builds the same tools
# and gdk-pixbuf loader.
# No dunglas/frankenphp:php8.6 image is published yet (2026-11-19): FRANKENPHP_IMAGE
# can point at a FrankenPHP built from its main branch on php:8.6-cli-bookworm.
ARG FRANKENPHP_IMAGE=dunglas/frankenphp:php8.6-bookworm

FROM ${FRANKENPHP_IMAGE} AS libheif

RUN apt-get update && apt-get install -y \
        build-essential \
        cmake \
        git \
        pkg-config \
        libmagickwand-dev \
        libde265-dev \
        libx265-dev \
        libaom-dev \
        libdav1d-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
    && git clone --depth 1 --branch v1.20.2 https://github.com/strukturag/libheif.git /usr/local/src/libheif \
    && mkdir /usr/local/src/libheif/build \
    && cd /usr/local/src/libheif/build \
    && cmake -DENABLE_AVIF=ON .. \
    && make -j"$(nproc)" \
    && make install DESTDIR=/libheif-install


FROM ${FRANKENPHP_IMAGE}

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

# Layer 1: System dependencies - runtime only. No compilers, cmake or -dev
# headers: libheif is built in the stage above, and install-php-extensions
# installs the -dev packages it needs and removes them in its own layer.
# Listed explicitly: the runtime libraries the custom libheif links to, and
# the image libraries/tools that used to arrive only as dependencies of the
# -dev packages (libtiffxx6 ... gir1.2-rsvg-2.0), so nothing image-related
# disappears with the headers.
# procps (ps, top, free, pgrep) is listed for debugging inside the container -
# it used to arrive only as a dependency of the tools below.
# No wkhtmltopdf, inkscape or librsvg2-bin (2026-10): the app never called them
# - inkscape was only ImageMagick's SVG delegate, and no upload accepts SVG and
# no stored image is one. Their Qt/GTK stacks and fonts went with them; every
# text the app draws uses the TTF files bundled in the app.
RUN chmod +x /usr/local/bin/wait-for-it \
    && mkdir -p /.composer /usr/tmp /docker-entrypoint.d /etc/frankenphp/Caddyfile.d /data \
    && apt-get update && apt-get install -y \
        git \
        zip \
        ca-certificates \
        curl \
        lsb-release \
        gnupg \
        wget \
        nano \
        procps \
        imagemagick \
        libmagickwand-6.q16-6 \
        libmagickcore-6.q16-6-extra \
        libde265-0 \
        libx265-199 \
        libaom3 \
        libdav1d6 \
        libnuma1 \
        libjpeg62-turbo \
        libpng16-16 \
        libwebp7 \
        libtiff6 \
        libtiffxx6 \
        libexif12 \
        libpng-tools \
        libcairo-script-interpreter2 \
        gir1.2-rsvg-2.0 \
        libgdk-pixbuf-2.0-0 \
        brotli \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: libheif with AVIF support (built in the libheif stage)
COPY --from=libheif /libheif-install/usr/local/ /usr/local/

# Layer 3: PHP extensions (the installer adds the -dev packages it needs and
# purges them, with everything they pulled in, before the layer is committed)
# PHP 8.6 (2026-11-19): official images no longer bundle mbstring, and opcache
# is always built in. The PECL releases of apcu, redis, excimer, imagick and
# xdebug do not compile on 8.6 yet (XtOffsetOf and zval_dtor were removed,
# xdebug 3.5 caps at 8.5.99) - imagick and xdebug come from pinned git commits
# through the installer, apcu, redis and excimer are compiled below (the
# installer cannot package their git trees). Back to plain names once PECL
# releases support 8.6.
RUN ldconfig \
    && install-php-extensions \
        @composer \
        mbstring \
        bcmath \
        intl \
        pcntl \
        zip \
        uuid \
        pdo_pgsql \
        gd \
        exif \
        xsl \
        Imagick/imagick@55ed2e9fda264395636a2e27e51f31673f5566ab \
        xdebug/xdebug@5e19866c1766e38c527f9f94faa170370dc4209f

RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends $PHPIZE_DEPS libzstd-dev liblz4-dev; \
    build() { \
        name="$1"; repo="$2"; sha="$3"; shift 3; \
        mkdir -p "/usr/src/$name"; \
        curl -fsSL "https://codeload.github.com/$repo/tar.gz/$sha" | tar -xz --strip-components=1 -C "/usr/src/$name"; \
        cd "/usr/src/$name"; phpize; ./configure "$@"; make -j"$(nproc)"; make install; \
        docker-php-ext-enable "$name"; cd /; rm -rf "/usr/src/$name"; \
    }; \
    build apcu krakjoe/apcu fb2c942552a3f5dab7f4dea4afb5cf0831222c57; \
    build redis phpredis/phpredis 5b60b125aba347159b0c9c319296fbb3c5ed9214 --enable-redis-zstd --with-libzstd --enable-redis-lz4 --with-liblz4; \
    build excimer wikimedia/mediawiki-php-excimer 34183f9487bf95cd5b8dab50af737d19de5179f7; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    apt-mark manual libzstd1 liblz4-1; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    php -m | grep -qx apcu; php -m | grep -qx redis; php -m | grep -qx excimer

# Xdebug stays installed but ships disabled: the entrypoint enables it only
# when XDEBUG_MODE is set (dev compose does). Merely loading the extension
# costs significant performance, so no derived image can run it by accident.
RUN mv "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini.disabled"

# Layer 4: Node.js and Sentry CLI
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && curl -sL https://sentry.io/get-cli/ | bash \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Debian's libheif1 comes back as a dependency of ImageMagick (imagick pulls
# it in), and its file wins SONAME resolution over /usr/local/lib,
# leaving the custom v1.20.2 AVIF build unused. Divert the distro files out of
# the linker's search path and assert the ImageMagick heic coder now resolves
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
