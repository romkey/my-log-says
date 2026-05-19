# LogLady

LogLady collects Docker container logs, stores unique log entries in PostgreSQL, and sends each unique entry to an inference server for LLM analysis. Duplicate log lines are counted on the original record and are not analyzed again.

## Requirements

- Ruby 3.3.11
- Rails 8.1.3
- PostgreSQL 18
- Redis 8
- Docker and Docker Compose

## Setup

Copy `.env.example` to `.env` and set the inference server values:

```sh
INFERENCE_URL=https://your-inference-server.example/analyze
INFERENCE_API_KEY=your-api-key
INFERENCE_MODEL=log-analyzer
```

By default the LLM prompt comes from `config/inference_prompt.example.txt`. Override it with `INFERENCE_PROMPT` (inline) or `INFERENCE_PROMPT_FILE` (path to a text file). The inference server should return JSON with `classification`, `urgency`, `needs_action`, `fixes`, and `other_suggestions` — see the example prompt for the expected schema.

Do not commit `.env`; API keys and production secrets must live outside the repository.

## Running Locally

Start the development stack:

```sh
docker compose -f docker-compose.dev.yml up
```

Prepare the database:

```sh
docker compose -f docker-compose.dev.yml --profile tools run --rm migrate
```

The app listens on `http://localhost:3000`. The dev PostgreSQL and Redis containers use the `loglady-` prefix and host ports `15432` and `16379` so they do not collide with other projects.

The dev, test, and lint stacks use the official `ruby:3.3.11` image with this repository bind-mounted into the container. They run `bundle check || bundle install` against a cached Bundler volume, so Gemfile changes do not require rebuilding a tool image.

## Ingesting Logs

Import recent Docker logs for a container:

```sh
docker compose -f docker-compose.dev.yml run --rm web ./bin/rails docker_logs:import CONTAINER=container-name
```

You can also post logs directly:

```sh
curl -X POST http://localhost:3000/log_entries \
  -H "Content-Type: application/json" \
  -d '{"log_entry":{"source_container":"web","stream":"stderr","message":"database timeout"}}'
```

Each log entry is fingerprinted by container, stream, and normalized message. When the same entry appears again, `occurrence_count` is incremented and no new analysis job is queued.

## Testing

```sh
docker compose -f docker-compose.test.yml run --rm test
```

## Linting

```sh
docker compose -f docker-compose.lint.yml run --rm rubocop
```

## Architecture

- `LogEntry` stores each unique log line, duplicate count, analysis status, and LLM output.
- `LogEntries::Ingestor` creates new entries and counts duplicates.
- `DockerLogs::Importer` reads Docker logs and sends them through the ingestor.
- `AnalyzeLogEntryJob` runs in Sidekiq on the `analysis` queue.
- `Inference::Client` calls the configured inference server with the API key from the environment.

## CI and Images

GitHub Actions runs Docker-based tests and linting. The Docker publish workflow builds and publishes an image to GitHub Container Registry on push, using branch, tag, and SHA tags.
