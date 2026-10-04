# libheif 1.20.2 with AVIF support, compiled in its own stage: the compiler
# toolchain, cmake and every -dev package it needs stay here, only the
# `make install` output is copied into the final image. libmagickwand-dev is
# installed for the -dev libraries it pulls in (tiff, gdk-pixbuf, ...), so
# libheif's cmake detects the same set as before and builds the same tools
# and gdk-pixbuf loader.
FROM dunglas/frankenphp:php8.5-bookworm AS libheif

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
RUN ldconfig \
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
