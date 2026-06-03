# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class LogLineClassifierTest < ActiveSupport::TestCase
    test 'detects home assistant primary lines' do
      message = '2026-06-03 07:01:31.838 WARNING (MainThread) [bond.entity] Entity unavailable'

      assert LogLineClassifier.primary_line?(message)
      assert_not LogLineClassifier.continuation_line?(message, traceback_open: false)
    end

    test 'detects traceback continuations without leading indentation' do
      assert LogLineClassifier.continuation_line?('Traceback (most recent call last):', traceback_open: false)

      frame = 'File "/bond/entity.py", line 142, in _async_update'
      assert LogLineClassifier.continuation_line?(frame, traceback_open: false)
      assert LogLineClassifier.continuation_line?('TimeoutError', traceback_open: false)
    end

    test 'treats blank lines as continuations only when traceback is open' do
      assert_not LogLineClassifier.continuation_line?('', traceback_open: false)
      assert LogLineClassifier.continuation_line?('', traceback_open: true)
    end

    test 'does not classify narrative lines as continuations' do
      message = 'continued narrative line without traceback shape'

      assert_not LogLineClassifier.primary_line?(message)
      assert_not LogLineClassifier.continuation_line?(message, traceback_open: true)
    end
  end
end
