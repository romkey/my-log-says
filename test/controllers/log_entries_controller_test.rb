# frozen_string_literal: true

require 'test_helper'

class LogEntriesControllerTest < ActionDispatch::IntegrationTest
  test 'lists log entries' do
    get log_entries_url

    assert_response :success
    assert_includes response.body, 'Retrying failed request'
    assert_includes response.body, 'Analyzed'
    assert_includes response.body, 'Failed'
  end

  test 'shows analyzed and failed counts as filter links' do
    get log_entries_url

    assert_select 'a.filter-chip[href=?]', log_entries_path(analysis: 'analyzed')
    assert_select 'a.filter-chip[href=?]', log_entries_path(analysis: 'failed')
    assert_includes response.body, log_entries(:analyzed_error).message
    assert_includes response.body, log_entries(:failed_inference).message
  end

  test 'filters to analyzed entries only' do
    get log_entries_url, params: { analysis: 'analyzed' }

    assert_response :success
    assert_includes response.body, log_entries(:analyzed_error).message
    assert_not_includes response.body, log_entries(:pending_warning).message
    assert_not_includes response.body, log_entries(:failed_inference).message
    assert_select 'a.filter-chip.active[href=?]', log_entries_path(analysis: 'analyzed')
    assert_includes response.body, 'Clear filter'
  end

  test 'filters to failed entries only' do
    get log_entries_url, params: { analysis: 'failed' }

    assert_response :success
    assert_includes response.body, log_entries(:failed_inference).message
    assert_not_includes response.body, log_entries(:analyzed_error).message
    assert_not_includes response.body, log_entries(:pending_warning).message
    assert_select 'a.filter-chip.active.danger[href=?]', log_entries_path(analysis: 'failed')
  end

  test 'ignores invalid analysis filter' do
    get log_entries_url, params: { analysis: 'bogus' }

    assert_response :success
    assert_includes response.body, log_entries(:pending_warning).message
    assert_not_includes response.body, 'Clear filter'
  end

  test 'ingests log entry as json' do
    assert_difference -> { LogEntry.count }, 1 do
      post log_entries_url, params: {
        log_entry: {
          source_container: 'api',
          stream: 'stderr',
          message: 'Unhandled exception'
        }
      }, as: :json
    end

    assert_response :created
    assert_equal 'application/json', response.media_type
  end
end
