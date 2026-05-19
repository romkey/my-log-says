# frozen_string_literal: true

require 'test_helper'

class LogEntryTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert log_entries(:pending_warning).valid?
  end

  test 'duplicate is based on occurrence count' do
    entry = log_entries(:pending_warning)
    assert_not entry.duplicate?

    entry.occurrence_count = 2
    assert entry.duplicate?
  end

  test 'requires a known analysis status' do
    entry = log_entries(:pending_warning)
    entry.analysis_status = 'unknown'

    assert_not entry.valid?
  end

  test 'requires known classification when set' do
    entry = log_entries(:analyzed_error)
    entry.classification = 'unknown'

    assert_not entry.valid?
  end
end
