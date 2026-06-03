# frozen_string_literal: true

module DockerLogs
  # Reads Docker logs from a container via the Docker Engine API and ingests each parsed log line.
  class Importer
    class Error < StandardError
    end

    Result = Data.define(:imported_count, :duplicate_count, :line_errors, :log_cursor_at)

    def self.call(docker_container:, client: Docker::Client.new, since: nil)
      new(docker_container: docker_container, client: client, since: since).call
    end

    def initialize(docker_container:, client:, since: nil)
      @docker_container = docker_container
      @client = client
      @since = since
    end

    def call
      raw_logs = client.container_logs(docker_container.docker_id, since: import_since)
      entries = StreamDemuxer.call(raw_logs)
      import(LineGrouper.call(entries))
    rescue Docker::Client::Error => e
      raise Error, e.message
    end

    private

    attr_reader :docker_container, :client, :since

    def import(entries)
      duplicates = []
      line_errors = []
      log_cursor_at = docker_container.log_cursor_at

      entries.each do |entry|
        duplicate, log_cursor_at = process_entry(entry, line_errors, log_cursor_at)
        duplicates << duplicate unless duplicate.nil?
      end

      build_result(duplicates, line_errors, log_cursor_at)
    end

    def process_entry(entry, line_errors, log_cursor_at)
      duplicate = import_entry(entry, line_errors)
      [duplicate, later_timestamp(log_cursor_at, entry.observed_at)]
    end

    def build_result(duplicates, line_errors, log_cursor_at)
      Result.new(
        imported_count: duplicates.length,
        duplicate_count: duplicates.count(true),
        line_errors: line_errors,
        log_cursor_at: log_cursor_at
      )
    end

    def import_entry(entry, line_errors)
      LogEntries::Ingestor.call(
        source_container: docker_container.name,
        stream: entry.stream,
        message: entry.message,
        observed_at: entry.observed_at,
        raw_payload: { 'docker_timestamp' => entry.timestamp }
      ).duplicate
    rescue StandardError => e
      line_errors << e.message
      nil
    end

    def import_since
      return since if since
      return docker_container.log_cursor_at if docker_container.log_cursor_at.present?

      SinceParser.call(ENV.fetch('DOCKER_LOGS_SINCE', '10m'))
    end

    def later_timestamp(current, candidate)
      return candidate if current.nil? || candidate > current

      current
    end
  end
end
