# frozen_string_literal: true

require 'test_helper'

class LogEntryTest < ActiveSupport::TestCase
  test 'validates analysis status inclusion' do
    entry = log_entries(:pending_warning)
    entry.analysis_status = 'unknown'

    assert_not entry.valid?
    assert_includes entry.errors[:analysis_status], 'is not included in the list'
  end

  test 'analyzed? reflects analysis status' do
    assert log_entries(:analyzed_error).analyzed?
    assert_not log_entries(:pending_warning).analyzed?
  end

  test 'with_analysis_status scope filters by status' do
    analyzed = LogEntry.with_analysis_status('analyzed')

    assert_includes analyzed, log_entries(:analyzed_error)
    assert_not_includes analyzed, log_entries(:failed_inference)
  end

  test 'with_container scope filters by source container' do
    web_entries = LogEntry.with_container('web')

    assert_includes web_entries, log_entries(:analyzed_error)
    assert_not_includes web_entries, log_entries(:pending_warning)
  end

  test 'with_severity scope filters by urgency' do
    high_entries = LogEntry.with_severity('high')

    assert_includes high_entries, log_entries(:analyzed_error)
    assert_not_includes high_entries, log_entries(:analyzed_info)
  end
end
