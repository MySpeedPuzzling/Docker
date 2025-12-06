#!/usr/bin/env bash

set -e

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

exec "$@"
