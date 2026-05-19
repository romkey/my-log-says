# Changelog

All notable changes to LogLady are documented here.

## [Unreleased]

## [0.2.1] - 2026-05-19

### Fixed

- RuboCop offenses in the analyzer, analysis parser, and structured analysis migration.
- Analysis parser handling of responses nested under an `analysis` key.

## [0.2.0] - 2026-05-19

### Added

- Configurable LLM analysis prompt via `INFERENCE_PROMPT` or `INFERENCE_PROMPT_FILE`, with `config/inference_prompt.example.txt` as the default.
- Structured analysis fields on log entries: classification, urgency, needs_action, fixes, and other_suggestions.
- Bootstrapped the Rails 8.1.3 application for Docker-based development, testing, linting, and server deployment.
- Added Docker log ingestion with duplicate detection and occurrence counting.
- Added Sidekiq-backed LLM analysis for unique log entries through a configurable inference server API key.
- Added PostgreSQL 18 and Redis 8 compose stacks with `loglady-` namespacing to avoid local service conflicts.
- Added Docker-based test and RuboCop workflows plus GitHub Container Registry image publishing on push.
- Added README setup, ingestion, testing, linting, architecture, and deployment documentation.

### Changed

- Renamed the project from MyLogSays to LogLady across code, Docker stacks, and documentation.
- Inference client now sends the prompt in the request payload and expects structured JSON analysis instead of free-text.
- Switched dev, test, and lint Compose stacks to the official Ruby image with a mounted Gemfile and cached Bundler volume so dependency changes no longer require rebuilding tool images.
