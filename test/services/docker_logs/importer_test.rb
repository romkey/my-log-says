# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class ImporterTest < ActiveJob::TestCase
    def multiplexed_log_line(message, stream_type: 1)
      payload = message
      [stream_type, 0, 0, 0, payload.bytesize].pack('C4N') + payload
    end

    test 'imports docker log lines via the docker api' do
      container = docker_containers(:web)
      logs = multiplexed_log_line("2026-05-11T03:30:00Z database timeout\n")
      client = fake_client(logs)

      assert_difference -> { LogEntry.count }, 1 do
        result = Importer.call(docker_container: container, client: client, since: 5.minutes.ago)

        assert_equal 1, result.imported_count
        assert_equal 0, result.duplicate_count
        assert_empty result.line_errors
      end
    end

    test 'reports duplicate imported lines' do
      container = docker_containers(:web)
      message = "2026-05-11T03:30:00Z database timeout\n"
      logs = multiplexed_log_line(message) + multiplexed_log_line(message)
      client = fake_client(logs)

      result = Importer.call(docker_container: container, client: client, since: 5.minutes.ago)

      assert_equal 2, result.imported_count
      assert_equal 1, result.duplicate_count
    end

    test 'continues when a log line fails to ingest' do
      container = docker_containers(:web)
      logs = multiplexed_log_line("2026-05-11T03:30:00Z database timeout\n")
      client = fake_client(logs)
      original_call = LogEntries::Ingestor.method(:call)
      calls = 0
      LogEntries::Ingestor.define_singleton_method(:call) do |**kwargs|
        calls += 1
        raise StandardError, 'ingest failed' if calls == 1

        original_call.call(**kwargs)
      end

      result = Importer.call(docker_container: container, client: client, since: 5.minutes.ago)

      assert_equal ['ingest failed'], result.line_errors
      assert_equal 0, result.imported_count
    ensure
      LogEntries::Ingestor.define_singleton_method(:call, original_call)
    end

    test 'groups traceback lines into a single log entry' do
      container = docker_containers(:web)
      warning = '2026-06-03 07:01:31.838 WARNING (MainThread) [bond.entity] Entity unavailable'
      lines = [
        "2026-06-03T07:01:31.838000000Z #{warning}\n",
        "2026-06-03T07:01:31.839000000Z Traceback (most recent call last):\n",
        "2026-06-03T07:01:31.840000000Z   File \"/bond/entity.py\", line 142, in _async_update\n",
        "2026-06-03T07:01:31.841000000Z TimeoutError\n"
      ].join
      logs = multiplexed_log_line(lines)
      client = fake_client(logs)

      assert_difference -> { LogEntry.count }, 1 do
        result = Importer.call(docker_container: container, client: client, since: 5.minutes.ago)

        assert_equal 1, result.imported_count
      end

      entry = LogEntry.order(:id).last

      assert_includes entry.message, warning
      assert_includes entry.message, 'Traceback (most recent call last):'
      assert_includes entry.message, 'TimeoutError'
    end

    test 'raises when docker logs fail' do
      container = docker_containers(:web)
      client = Object.new
      client.define_singleton_method(:container_logs) { |*| raise Docker::Client::Error, 'container not found' }

      error = assert_raises Importer::Error do
        Importer.call(docker_container: container, client: client)
      end

      assert_equal 'container not found', error.message
    end

    private

    def fake_client(logs)
      Object.new.tap do |client|
        client.define_singleton_method(:container_logs) { |*_args| logs }
      end
    end
  end
end
