# Changelog

All notable changes to LogLady are documented here.

## [Unreleased]

## [0.3.11] - 2026-06-03

### Added

- UI to exclude containers from LLM analysis (index chips and log entry detail actions).
- `skip_analysis` flag on tracked containers; excluded entries get `analysis_status: excluded`.
- **Excluded** analysis filter chip when excluded entries exist.

## [0.3.10] - 2026-06-03

### Added

- Stacked log entry filters: **Analysis**, **Container**, and **Severity** combine via query params.
- Severity column on the log entries table.
- Click an active filter chip again to remove that facet.

## [0.3.9] - 2026-06-03

### Added

- Log entries index: clickable **Analyzed** and **Failed** filter chips with counts.
- `refresh.css` for compact table, filter chips, and status dots (replaces yellow Bootstrap warnings).

### Changed

- Failed analysis rows use danger-subtle badges and dots instead of yellow table highlighting.
- Log entry rows are clickable to open detail view.

## [0.3.8] - 2026-06-03

### Added

- `INFERENCE_API_FORMAT` env var: `loglady` (default) or `openai` for OpenAI-compatible chat completions endpoints.

### Fixed

- Permanent inference errors (405, 401, etc.) no longer retry indefinitely; entries are marked failed once.
- Sidekiq only retries transient inference failures (408, 429, 5xx).

## [0.2.2] - 2026-05-19

### Added

- Settings page to edit the inference prompt in the running app (stored in the database).
- Optional `INFERENCE_FALLBACK_MODEL` to retry analysis when the primary model is unavailable.

### Changed

- Inference prompt resolution order: `INFERENCE_PROMPT` env, database, then example file.

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
