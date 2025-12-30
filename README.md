# [MySpeedPuzzling.com](https://myspeedpuzzling.com) Docker base images

Images are built automatically using Github actions and pushed to Github Container Registry (ghcr.io).

## web-base-php85

PHP 8.5 base image using FrankenPHP (Caddy).

**Features:** FrankenPHP worker mode, Mercure hub, full-duplex HTTP/1.1, PHP extensions (bcmath, intl, pcntl, zip, uuid, pdo_pgsql, opcache, apcu, gd, exif, redis, excimer, xsl, imagick, xdebug), libheif with AVIF, Node.js LTS.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FRANKENPHP_WORKER` | `""` | Set to `1` to enable worker mode |
| `FRANKENPHP_WORKER_FILE` | `/app/public/index.php` | Worker script path |
| `FRANKENPHP_WORKER_NUM` | auto | Number of workers (2x CPUs) |
| `FRANKENPHP_WATCH` | `""` | Set to `1` for file watching (dev) |
| `FRANKENPHP_WATCH_PATHS` | `./src/**/*.php ./config/**/*.{yaml,yml} ./templates/**/*.twig` | Watch patterns |
| `MERCURE_PUBLISHER_JWT_KEY` | `""` | JWT secret for Mercure publishers |
| `MERCURE_SUBSCRIBER_JWT_KEY` | `""` | JWT secret for Mercure subscribers |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `1` | Set `0` for production |

### Usage

```yaml
# Production
services:
  app:
    image: ghcr.io/myspeedpuzzling/web-base-php85
    environment:
      FRANKENPHP_WORKER: "1"
      PHP_OPCACHE_VALIDATE_TIMESTAMPS: "0"

# Development
services:
  app:
    image: ghcr.io/myspeedpuzzling/web-base-php85
    environment:
      FRANKENPHP_WORKER: "1"
      FRANKENPHP_WATCH: "1"
    volumes:
      - ./:/app
```

**Symfony:** `composer require runtime/frankenphp-symfony` and set `APP_RUNTIME=Runtime\FrankenPhpSymfony\Runtime`

**Extensibility:** Mount Caddyfile snippets to `/etc/frankenphp/Caddyfile.d/*.caddyfile`

**Init scripts:** Place `.sh` files in `/docker-entrypoint.d/`
