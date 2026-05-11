# frozen_string_literal: true

require 'test_helper'

class LogEntriesControllerTest < ActionDispatch::IntegrationTest
  test 'lists log entries' do
    get log_entries_url

    assert_response :success
    assert_includes response.body, 'Retrying failed request'
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
