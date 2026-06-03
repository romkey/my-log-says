# frozen_string_literal: true

require 'test_helper'

class LogEntriesStreamTest < ActionDispatch::IntegrationTest
  test 'show links to container stream' do
    entry = log_entries(:analyzed_error)
    get log_entry_url(entry)

    assert_response :success
    stream_path = log_entries_path(
      container: entry.source_container,
      focus: entry.id,
      anchor: "log-entry-#{entry.id}"
    )
    assert_select 'a.btn[href=?]', stream_path
  end

  test 'container stream filters by container and scrolls to focus' do
    entry = log_entries(:analyzed_error)
    get log_entries_url, params: { container: 'web', focus: entry.id, anchor: "log-entry-#{entry.id}" }

    assert_response :success
    assert_select 'h1', text: 'web'
    assert_select format('tr#log-entry-%d', entry.id)
    assert_select 'a.filter-chip.active', text: /web/
    assert_includes response.body, entry.message
    assert_includes response.body, log_entries(:analyzed_info).message
    assert_not_includes response.body, log_entries(:pending_warning).message
  end

  test 'focus alone applies container filter for stream context' do
    entry = log_entries(:pending_warning)
    get log_entries_url, params: { focus: entry.id }

    assert_response :success
    assert_select 'h1', text: 'worker'
    assert_select format('tr#log-entry-%d', entry.id)
    assert_includes response.body, entry.message
    assert_not_includes response.body, log_entries(:analyzed_error).message
  end
end
