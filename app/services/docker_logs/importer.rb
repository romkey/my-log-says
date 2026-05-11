# frozen_string_literal: true

require 'open3'

module DockerLogs
  # Reads Docker logs from a container and ingests each parsed log line.
  class Importer
    class Error < StandardError
    end

    Result = Data.define(:imported_count, :duplicate_count)

    def self.call(container_name:, since: ENV.fetch('DOCKER_LOGS_SINCE', '10m'),
                  command_runner: Open3.method(:capture3))
      new(container_name: container_name, since: since, command_runner: command_runner).call
    end

    def initialize(container_name:, since: ENV.fetch('DOCKER_LOGS_SINCE', '10m'),
                   command_runner: Open3.method(:capture3))
      @container_name = container_name
      @since = since
      @command_runner = command_runner
    end

    def call
      stdout, stderr, status = command_runner.call(*command)
      raise Error, stderr.presence || "docker logs failed for #{container_name}" unless status.success?

      import(stdout)
    end

    private

    attr_reader :container_name, :since, :command_runner

    def command
      ['docker', 'logs', '--timestamps', "--since=#{since}", container_name]
    end

    def import(output)
      duplicates = output.each_line.map { |line| import_line(line) }.compact

      Result.new(imported_count: duplicates.length, duplicate_count: duplicates.count(true))
    end

    def import_line(line)
      parsed = parse_line(line)
      return if parsed[:message].blank?

      LogEntries::Ingestor.call(
        source_container: container_name,
        stream: 'docker',
        message: parsed[:message],
        observed_at: parsed[:observed_at],
        raw_payload: { 'docker_timestamp' => parsed[:timestamp] }
      ).duplicate
    end

    def parse_line(line)
      timestamp, message = line.strip.split(/\s+/, 2)
      {
        timestamp: timestamp,
        observed_at: parse_timestamp(timestamp),
        message: message.to_s
      }
    end

    def parse_timestamp(timestamp)
      Time.zone.parse(timestamp)
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
