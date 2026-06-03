# frozen_string_literal: true

require 'test_helper'

module Inference
  class RequestBuilderTest < ActiveSupport::TestCase
    test 'builds loglady request with custom payload' do
      entry = log_entries(:pending_warning)
      request = RequestBuilder.build(
        log_entry: entry,
        model_name: 'log-analyzer',
        prompt: 'Analyze logs.',
        endpoint: 'https://example.test/analyze',
        api_format: 'loglady'
      )

      assert_equal 'POST', request.method
      assert_equal '/analyze', request.path
      body = JSON.parse(request.body)
      assert_equal 'log-analyzer', body['model']
      assert_equal 'Analyze logs.', body['prompt']
      assert_equal entry.id, body['log_entry']['id']
      assert_equal entry.message, body['log_entry']['message']
    end

    test 'builds openai request with chat completions path' do
      entry = log_entries(:pending_warning)
      request = RequestBuilder.build(
        log_entry: entry,
        model_name: 'gpt-4o-mini',
        prompt: 'Analyze logs.',
        endpoint: 'https://example.test/v1',
        api_format: 'openai'
      )

      assert_equal '/v1/chat/completions', request.path
      body = JSON.parse(request.body)
      assert_equal 'gpt-4o-mini', body['model']
      assert_equal 'system', body['messages'].first['role']
      assert_equal 'Analyze logs.', body['messages'].first['content']
      assert_equal 'user', body['messages'].last['role']
      assert_includes body['messages'].last['content'], entry.message
    end

    test 'preserves existing chat completions path' do
      request = RequestBuilder.build(
        log_entry: log_entries(:pending_warning),
        model_name: 'gpt-4o-mini',
        prompt: 'Analyze logs.',
        endpoint: 'https://example.test/v1/chat/completions',
        api_format: 'openai'
      )

      assert_equal '/v1/chat/completions', request.path
    end
  end
end
