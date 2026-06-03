# frozen_string_literal: true

require 'test_helper'

class AnalyzeLogEntryJobTest < ActiveJob::TestCase
  test 'analyzes the requested log entry' do
    test_case = self
    entry = log_entries(:pending_warning)
    original_call = LogEntries::Analyzer.method(:call)
    LogEntries::Analyzer.define_singleton_method(:call) { |actual_entry| test_case.assert_equal entry, actual_entry }

    AnalyzeLogEntryJob.perform_now(entry.id)
  ensure
    LogEntries::Analyzer.define_singleton_method(:call, original_call)
  end

  test 'ignores stale jobs for deleted log entries' do
    assert_nothing_raised do
      AnalyzeLogEntryJob.perform_now(-1)
    end
  end

  test 'skips analysis for excluded containers' do
    entry = log_entries(:pending_warning)
    docker_containers(:web).update!(name: entry.source_container, skip_analysis: true)
    called = false
    original_call = LogEntries::Analyzer.method(:call)
    LogEntries::Analyzer.define_singleton_method(:call) { |_entry| called = true }

    AnalyzeLogEntryJob.perform_now(entry.id)

    assert_not called
  ensure
    LogEntries::Analyzer.define_singleton_method(:call, original_call)
  end
end
