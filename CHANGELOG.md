# Changelog

All notable changes to MyLogSays are documented here.

## [Unreleased]

### Added

- Bootstrapped the Rails 8.1.3 application for Docker-based development, testing, linting, and server deployment.
- Added Docker log ingestion with duplicate detection and occurrence counting.
- Added Sidekiq-backed LLM analysis for unique log entries through a configurable inference server API key.
- Added PostgreSQL 18 and Redis 8 compose stacks with `mylogsays-` namespacing to avoid local service conflicts.
- Added Docker-based test and RuboCop workflows plus GitHub Container Registry image publishing on push.
- Added README setup, ingestion, testing, linting, architecture, and deployment documentation.

### Changed

- Switched dev, test, and lint Compose stacks to the official Ruby image with a mounted Gemfile and cached Bundler volume so dependency changes no longer require rebuilding tool images.
