# frozen_string_literal: true

require 'test_helper'

module Inference
  class ResponseBodyTest < ActiveSupport::TestCase
    ANALYSIS = {
      'classification' => 'informational',
      'urgency' => 'low',
      'needs_action' => false,
      'fixes' => [],
      'other_suggestions' => []
    }.freeze

    test 'passes through loglady response unchanged' do
      data = { 'analysis' => ANALYSIS }

      normalized = ResponseBody.normalize(data, api_format: 'loglady')

      assert_equal data, normalized
    end

    test 'extracts json content from openai chat completion' do
      data = {
        'choices' => [
          { 'message' => { 'content' => ANALYSIS.to_json } }
        ]
      }

      normalized = ResponseBody.normalize(data, api_format: 'openai')

      assert_equal ANALYSIS, normalized
    end

    test 'raises when openai response is missing content' do
      data = { 'choices' => [{ 'message' => {} }] }

      error = assert_raises Client::Error do
        ResponseBody.normalize(data, api_format: 'openai')
      end

      assert_equal 'OpenAI response missing message content', error.message
      assert_equal 200, error.status_code
    end
  end
end
