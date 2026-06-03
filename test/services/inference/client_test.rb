# frozen_string_literal: true

require 'test_helper'

module Inference
  class ClientTest < ActiveSupport::TestCase
    test 'requires endpoint configuration' do
      client = Client.new(endpoint: nil, api_key: 'secret')

      error = assert_raises Client::ConfigurationError do
        client.analyze(log_entries(:pending_warning))
      end

      assert_equal 'INFERENCE_URL is required', error.message
    end

    test 'requires api key configuration' do
      client = Client.new(endpoint: 'https://example.test/analyze', api_key: nil)

      error = assert_raises Client::ConfigurationError do
        client.analyze(log_entries(:pending_warning))
      end

      assert_equal 'INFERENCE_API_KEY is required', error.message
    end

    test 'requires prompt configuration' do
      client = Client.new(
        endpoint: 'https://example.test/analyze',
        api_key: 'secret',
        prompt: ''
      )

      error = assert_raises Client::ConfigurationError do
        client.analyze(log_entries(:pending_warning))
      end

      assert_equal 'INFERENCE_PROMPT is required', error.message
    end

    test '405 errors are not retryable' do
      error = Client::Error.new('Method Not Allowed', status_code: 405)

      assert_not error.retryable?
    end

    test '503 errors are retryable' do
      error = Client::RetryableError.new('Service Unavailable', status_code: 503)

      assert error.retryable?
    end

    test 'rejects unknown api format' do
      client = Client.new(
        endpoint: 'https://example.test/analyze',
        api_key: 'secret',
        prompt: 'Analyze.',
        api_format: 'anthropic'
      )

      error = assert_raises Client::ConfigurationError do
        client.analyze(log_entries(:pending_warning))
      end

      assert_match(/INFERENCE_API_FORMAT/, error.message)
    end
  end
end
