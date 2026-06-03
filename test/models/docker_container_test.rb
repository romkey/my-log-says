# frozen_string_literal: true

require 'test_helper'

class DockerContainerTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert docker_containers(:web).valid?
  end

  test 'marks import state transitions' do
    container = docker_containers(:web)

    container.mark_importing!

    assert_equal 'importing', container.import_status
    assert_nil container.import_error

    timestamp = Time.zone.parse('2026-05-11T03:30:00Z')
    container.mark_import_succeeded!(log_cursor_at: timestamp)

    assert_equal 'succeeded', container.import_status
    assert_equal timestamp, container.log_cursor_at
    assert_not_nil container.last_imported_at

    container.mark_import_failed!('boom')

    assert_equal 'failed', container.import_status
    assert_equal 'boom', container.import_error
  end

  test 'exclude_from_analysis marks pending entries excluded' do
    container = docker_containers(:web)
    entry = log_entries(:pending_warning)
    entry.update!(source_container: 'web', analysis_status: 'pending')

    container.exclude_from_analysis!

    assert container.skip_analysis?
    assert_equal 'excluded', entry.reload.analysis_status
  end
end
