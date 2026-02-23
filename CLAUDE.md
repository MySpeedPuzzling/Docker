# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Docker base images for the Speedpuzzling.cz project. Images are automatically built via GitHub Actions and pushed to GitHub Container Registry (ghcr.io).

## Architecture

Single base image variant:
- `web-base-php85/` - PHP 8.5 based on FrankenPHP (Caddy), includes Inkscape, librsvg2

Contains:
- `Dockerfile` - Main image definition
- `php.ini` - PHP configuration overrides
- `bin/docker-entrypoint.sh` - Container entrypoint script
- `bin/wait-for-it.sh` - Utility for waiting on services
- `Caddyfile` - Caddy/FrankenPHP server configuration
- `imagemagick-policy.xml` - ImageMagick security policy

## FrankenPHP Worker Mode

The entrypoint script constructs FrankenPHP config from environment variables:

- **Single pool**: Workers go in the global `frankenphp {}` block via `FRANKENPHP_CONFIG`
- **Split pools**: When `FRANKENPHP_IMAGE_WORKER_NUM` + `FRANKENPHP_IMAGE_WORKER_MATCH` are set, workers go in the `php_server {}` block via `PHP_SERVER_CONFIG` (required because `match` directive only works inside `php_server`)

Key env vars: `FRANKENPHP_WORKER`, `FRANKENPHP_WORKER_NUM`, `FRANKENPHP_MAX_WAIT_TIME`, `FRANKENPHP_IMAGE_WORKER_NUM`, `FRANKENPHP_IMAGE_WORKER_MATCH`

## Building Images Locally

```bash
docker build -t web-base-php85 ./web-base-php85
```

## CI/CD

GitHub Actions workflows in `.github/workflows/` automatically build and push images on:
- Push to `main` branch
- Version tags (`v*.*.*`)

Images are published to:
- `ghcr.io/myspeedpuzzling/web-base-php85`

## Key Components

- **FrankenPHP**: Application server on port 8080, worker mode with split pool support
- **PHP Extensions**: bcmath, intl, pcntl, zip, uuid, pdo_pgsql, opcache, apcu, gd, exif, redis, xdebug, excimer, xsl, imagick
- **libheif**: Custom build with AVIF support for image processing
- **Node.js**: LTS version included for frontend tooling
