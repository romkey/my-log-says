# frozen_string_literal: true

require 'test_helper'

class ImportDockerLogsJobTest < ActiveJob::TestCase
  test 'imports logs for the requested container' do
    container = docker_containers(:web)
    test_case = self
    original_call = DockerLogs::Importer.method(:call)
    DockerLogs::Importer.define_singleton_method(:call) do |docker_container:|
      test_case.assert_equal container, docker_container
      DockerLogs::Importer::Result.new(
        imported_count: 1,
        duplicate_count: 0,
        line_errors: [],
        log_cursor_at: Time.zone.parse('2026-05-11T03:30:00Z')
      )
    end

    ImportDockerLogsJob.perform_now(container.id)

    container.reload

    assert_equal 'succeeded', container.import_status
    assert_nil container.import_error
    assert_equal Time.zone.parse('2026-05-11T03:30:00Z'), container.log_cursor_at
  ensure
    DockerLogs::Importer.define_singleton_method(:call, original_call)
  end

  test 'ignores stale jobs for missing containers' do
    assert_nothing_raised do
      ImportDockerLogsJob.perform_now(-1)
    end
  end

  test 'marks the container failed when import fails' do
    container = docker_containers(:web)
    original_call = DockerLogs::Importer.method(:call)
    DockerLogs::Importer.define_singleton_method(:call) do |**|
      raise DockerLogs::Importer::Error, 'socket unavailable'
    end

    ImportDockerLogsJob.perform_now(container.id)

    container.reload

    assert_equal 'failed', container.import_status
    assert_equal 'socket unavailable', container.import_error
  ensure
    DockerLogs::Importer.define_singleton_method(:call, original_call)
  end
end
