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
  end
end
