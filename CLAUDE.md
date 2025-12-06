# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Docker base images for the Speedpuzzling.cz project. Images are automatically built via GitHub Actions and pushed to GitHub Container Registry (ghcr.io).

## Architecture

Two base image variants:
- `web-base/` - PHP 8.3 based on NGINX Unit (`unit:php8.3`)
- `web-base-php84/` - PHP 8.4 based on NGINX Unit (`unit:php8.4`), includes additional tools (Inkscape, librsvg2)

Each variant contains:
- `Dockerfile` - Main image definition
- `php.ini` - PHP configuration overrides
- `bin/docker-entrypoint.sh` - Container entrypoint script
- `bin/wait-for-it.sh` - Utility for waiting on services
- `unit/config.json` - NGINX Unit server configuration

## Building Images Locally

```bash
# PHP 8.3 variant
docker build -t web-base ./web-base

# PHP 8.4 variant
docker build -t web-base-php84 ./web-base-php84
```

## CI/CD

GitHub Actions workflows in `.github/workflows/` automatically build and push images on:
- Push to `main` branch
- Version tags (`v*.*.*`)

Images are published to:
- `ghcr.io/myspeedpuzzling/web-base`
- `ghcr.io/myspeedpuzzling/web-base-php84`

The PHP 8.4 variant builds for both `linux/amd64` and `linux/arm64` platforms.

## Key Components

- **NGINX Unit**: Application server running on port 8080
- **PHP Extensions**: bcmath, intl, pcntl, zip, uuid, pdo_pgsql, opcache, apcu, gd, exif, redis, xdebug, excimer, xsl, imagick
- **libheif**: Custom build (v1.19.5) with AVIF support for image processing
- **Node.js**: LTS version included for frontend tooling
