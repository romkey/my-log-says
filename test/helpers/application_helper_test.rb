# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test 'filter chip links to analysis filter' do
    html = log_entry_filter_chip(label: 'Analyzed', count: 5, filter: 'analyzed', active_filter: nil)

    assert_includes html, log_entries_path(analysis: 'analyzed')
    assert_includes html, 'Analyzed'
    assert_includes html, '>5<'
  end

  test 'active filter chip includes active class' do
    html = log_entry_filter_chip(
      label: 'Failed', count: 2, filter: 'failed', active_filter: 'failed', variant: 'danger'
    )

    assert_includes html, 'filter-chip active danger'
  end
end
