# frozen_string_literal: true

require 'test_helper'

class LogEntriesControllerTest < ActionDispatch::IntegrationTest
  test 'lists log entries' do
    get log_entries_url

    assert_response :success
    assert_includes response.body, 'Retrying failed request'
    assert_includes response.body, 'Analyzed'
    assert_includes response.body, 'Failed'
    assert_includes response.body, 'Container'
    assert_includes response.body, 'Severity'
  end

  test 'shows filter chips with counts' do
    get log_entries_url

    assert_select 'a.filter-chip[href=?]', log_entries_path(analysis: 'analyzed')
    assert_select 'a.filter-chip[href=?]', log_entries_path(container: 'web')
    assert_select 'a.filter-chip[href=?]', log_entries_path(severity: 'high')
  end

  test 'filters to analyzed entries only' do
    get log_entries_url, params: { analysis: 'analyzed' }

    assert_response :success
    assert_includes response.body, log_entries(:analyzed_error).message
    assert_includes response.body, log_entries(:analyzed_info).message
    assert_not_includes response.body, log_entries(:pending_warning).message
    assert_not_includes response.body, log_entries(:failed_inference).message
    assert_select 'a.filter-chip.active', text: /Analyzed/
    assert_includes response.body, '1 filter active'
  end

  test 'filters to failed entries only' do
    get log_entries_url, params: { analysis: 'failed' }

    assert_response :success
    assert_includes response.body, log_entries(:failed_inference).message
    assert_not_includes response.body, log_entries(:analyzed_error).message
    assert_select 'a.filter-chip.active.danger', text: /Failed/
  end

  test 'filters by container' do
    get log_entries_url, params: { container: 'worker' }

    assert_response :success
    assert_includes response.body, log_entries(:pending_warning).message
    assert_not_includes response.body, log_entries(:analyzed_error).message
    assert_includes response.body, '1 filter active'
    assert_match(/filter-chip active[^>]*>worker/, response.body)
  end

  test 'filters by severity' do
    get log_entries_url, params: { severity: 'high' }

    assert_response :success
    assert_includes response.body, log_entries(:analyzed_error).message
    assert_not_includes response.body, log_entries(:analyzed_info).message
    assert_select 'a.filter-chip.active.danger', text: /High/
  end

  test 'stacked filters combine' do
    get log_entries_url, params: { analysis: 'analyzed', container: 'web', severity: 'high' }

    assert_response :success
    assert_includes response.body, log_entries(:analyzed_error).message
    assert_not_includes response.body, log_entries(:analyzed_info).message
    assert_includes response.body, '3 filters active'
    assert_select 'a.filter-chip.active', minimum: 3
  end

  test 'stacked filter links preserve other facets' do
    get log_entries_url, params: { analysis: 'analyzed', container: 'web' }

    assert_select 'a.filter-chip[href=?]', log_entries_path(analysis: 'analyzed', container: 'web', severity: 'high')
  end

  test 'ignores invalid analysis filter' do
    get log_entries_url, params: { analysis: 'bogus' }

    assert_response :success
    assert_includes response.body, log_entries(:pending_warning).message
    assert_not_includes response.body, 'filters active'
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
