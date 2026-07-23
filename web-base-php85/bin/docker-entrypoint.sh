#!/usr/bin/env bash

set -e

# Enable Xdebug only when explicitly requested. The image ships the ini
# disabled (docker-php-ext-xdebug.ini.disabled); merely loading the extension
# costs significant performance, so it must be opt-in via XDEBUG_MODE.
# In production images that delete both ini files this is a no-op.
XDEBUG_INI_DIR="${PHP_INI_DIR:-/usr/local/etc/php}/conf.d"
if [ -n "${XDEBUG_MODE:-}" ] && [ "${XDEBUG_MODE}" != "off" ]; then
    if [ -f "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini.disabled" ]; then
        mv "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini.disabled" "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini"
    fi
    echo "$0: Xdebug enabled (XDEBUG_MODE=${XDEBUG_MODE})"
elif [ -f "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini" ]; then
    mv "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini" "${XDEBUG_INI_DIR}/docker-php-ext-xdebug.ini.disabled"
    echo "$0: Xdebug disabled (XDEBUG_MODE not set)"
fi

# Execute shell scripts from /docker-entrypoint.d/ if present
# This allows for custom initialization (e.g., Doctrine migrations)
# Scripts are executed in alphabetical order, so prefix with numbers for ordering:
#   /docker-entrypoint.d/01-migrations.sh
#   /docker-entrypoint.d/02-cache-warmup.sh

if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -print -quit 2>/dev/null | /bin/grep -q .; then
    echo "$0: /docker-entrypoint.d/ is not empty, executing initialization scripts..."

    echo "$0: Looking for shell scripts in /docker-entrypoint.d/..."
    for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -name "*.sh" | sort); do
        echo "$0: Launching $f";
        chmod +x "$f"
        "$f"
    done

    # Warn on file types we don't know what to do with
    for f in $(/usr/bin/find /docker-entrypoint.d/ -type f -not -name "*.sh"); do
        echo "$0: Ignoring $f (not a .sh file)";
    done

    echo
    echo "$0: Initialization complete; starting FrankenPHP..."
    echo
else
    echo "$0: /docker-entrypoint.d/ is empty, skipping initialization..."
fi

# Construct FRANKENPHP_CONFIG from helper environment variables
# Only if FRANKENPHP_CONFIG is not already set directly
if [ -z "${FRANKENPHP_CONFIG}" ] && [ "${FRANKENPHP_WORKER}" = "1" ]; then
    WORKER_FILE="${FRANKENPHP_WORKER_FILE:-/app/public/index.php}"

    CONFIG="worker {
        file ${WORKER_FILE}"

    if [ -n "${FRANKENPHP_WORKER_NUM}" ]; then
        CONFIG="${CONFIG}
        num ${FRANKENPHP_WORKER_NUM}"
    fi

    if [ "${FRANKENPHP_WATCH}" = "1" ]; then
        # Default watch patterns - disable glob expansion to preserve patterns
        WATCH_PATHS="${FRANKENPHP_WATCH_PATHS:-./src/**/*.php ./config/**/*.{yaml,yml} ./templates/**/*.twig}"
        set -f  # Disable glob expansion
        for path in ${WATCH_PATHS}; do
            CONFIG="${CONFIG}
        watch ${path}"
        done
        set +f  # Re-enable glob expansion
    fi

    CONFIG="${CONFIG}
    }"

    # Add max_wait_time (sibling of worker block in global frankenphp directive)
    if [ -n "${FRANKENPHP_MAX_WAIT_TIME}" ]; then
        CONFIG="${CONFIG}
    max_wait_time ${FRANKENPHP_MAX_WAIT_TIME}"
    fi

    export FRANKENPHP_CONFIG="${CONFIG}"

    echo "$0: Worker mode enabled"
fi

exec "$@"
