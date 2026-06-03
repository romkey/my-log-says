# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  def filters(**attrs)
    LogEntries::Filters.new(base_scope: LogEntry.all, **attrs)
  end

  test 'filter chip links preserve stacked filters' do
    html = log_entry_filter_chip(
      filters: filters(analysis: 'analyzed', container: 'web'),
      facet: :severity,
      value: 'high',
      label: 'High',
      count: 1
    )

    assert_includes html, 'severity=high'
    assert_includes html, 'container=web'
    assert_includes html, 'analysis=analyzed'
  end

  test 'active filter chip links toggle facet off' do
    html = log_entry_filter_chip(
      filters: filters(analysis: 'analyzed'),
      facet: :analysis,
      value: 'analyzed',
      label: 'Analyzed',
      count: 2
    )

    assert_includes html, log_entries_path
    assert_not_includes html, 'analysis=analyzed'
    assert_includes html, 'filter-chip active'
  end

  test 'severity label highlights high urgency' do
    html = log_entry_severity_label(log_entries(:analyzed_error))

    assert_includes html, 'High'
    assert_includes html, 'text-bg-danger-subtle'
  end

  test 'severity label mutes missing urgency' do
    html = log_entry_severity_label(log_entries(:pending_warning))

    assert_includes html, '—'
  end
end
