# frozen_string_literal: true

require 'test_helper'

module Inference
  class ErrorContextTest < ActiveSupport::TestCase
    test 'appends formatted hash to message' do
      message = ErrorContext.append({ 'status' => 'bad' }, 'Something failed')

      assert_equal 'Something failed. Response: {"status":"bad"}', message
    end

    test 'returns message unchanged when source is blank' do
      assert_equal 'Something failed', ErrorContext.append('', 'Something failed')
      assert_equal 'Something failed', ErrorContext.append(nil, 'Something failed')
    end

    test 'truncates very long responses' do
      long_text = 'x' * (ErrorContext::MAX_LENGTH + 100)
      formatted = ErrorContext.format(long_text)

      assert_match(/\A#{'x' * ErrorContext::MAX_LENGTH}…/, formatted)
      assert_match(/#{long_text.length} bytes total\)\z/, formatted)
    end
  end
end
