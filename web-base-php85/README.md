# web-base-php85

PHP 8.5 Docker base image using FrankenPHP (Caddy).

## Features

- FrankenPHP with optional worker mode
- Mercure hub for real-time messaging
- Full-duplex HTTP/1.1 (SSE, streaming)
- PHP extensions: bcmath, intl, pcntl, zip, uuid, pdo_pgsql, opcache, apcu, gd, exif, redis, excimer, xsl, imagick, xdebug
- libheif with AVIF support
- Node.js LTS

## Environment Variables

### FrankenPHP Worker Mode

| Variable | Default | Description |
|----------|---------|-------------|
| `FRANKENPHP_WORKER` | `""` | Set to `1` to enable worker mode |
| `FRANKENPHP_WORKER_FILE` | `/app/public/index.php` | Worker script path |
| `FRANKENPHP_WORKER_NUM` | auto | Number of workers (default: 2x CPUs) |
| `FRANKENPHP_WATCH` | `""` | Set to `1` to enable file watching (dev) |
| `FRANKENPHP_WATCH_PATHS` | `./src/**/*.php ./config/**/*.{yaml,yml} ./templates/**/*.twig` | Watch patterns |
| `FRANKENPHP_CONFIG` | `""` | Direct config injection (advanced) |

### Mercure Hub

| Variable | Default | Description |
|----------|---------|-------------|
| `MERCURE_PUBLISHER_JWT_KEY` | `""` | JWT secret for publishers |
| `MERCURE_SUBSCRIBER_JWT_KEY` | `""` | JWT secret for subscribers |

### PHP OPcache

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `1` | Revalidate scripts (set `0` for prod) |
| `PHP_OPCACHE_MAX_ACCELERATED_FILES` | `15000` | Max cached scripts |
| `PHP_OPCACHE_MEMORY_CONSUMPTION` | `192` | Memory in MB |

## Usage Examples

### Production (worker mode)

```yaml
services:
  app:
    image: ghcr.io/myspeedpuzzling/web-base-php85
    environment:
      FRANKENPHP_WORKER: "1"
      FRANKENPHP_WORKER_NUM: "4"
      PHP_OPCACHE_VALIDATE_TIMESTAMPS: "0"
      MERCURE_PUBLISHER_JWT_KEY: "your-secret-key"
      MERCURE_SUBSCRIBER_JWT_KEY: "your-secret-key"
```

### Development (worker + file watching)

```yaml
services:
  app:
    image: ghcr.io/myspeedpuzzling/web-base-php85
    environment:
      FRANKENPHP_WORKER: "1"
      FRANKENPHP_WATCH: "1"
    volumes:
      - ./:/app
```

### Non-worker mode (default)

No configuration needed - works as traditional PHP request handling.

### Symfony Integration

For Symfony applications with worker mode:

```bash
composer require runtime/frankenphp-symfony
```

```yaml
environment:
  APP_RUNTIME: "Runtime\\FrankenPhpSymfony\\Runtime"
```

## Extensibility

Mount custom Caddyfile snippets to `/etc/frankenphp/Caddyfile.d/*.caddyfile`.

## Initialization Scripts

Place `.sh` scripts in `/docker-entrypoint.d/` for custom initialization (migrations, cache warmup, etc.). Scripts run in alphabetical order before FrankenPHP starts.
