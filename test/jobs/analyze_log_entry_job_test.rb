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
end
