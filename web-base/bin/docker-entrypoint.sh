#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- frankenphp run "$@"
fi

echo "$0: Looking for shell scripts in /docker-entrypoint.d/..."
for f in $(find /docker-entrypoint.d/ -type f -name "*.sh"); do
    echo "$0: Launching $f";
    "$f"
done

exec "$@"
