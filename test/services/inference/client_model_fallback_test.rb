# frozen_string_literal: true

require 'test_helper'

module Inference
  class ClientModelFallbackTest < ActiveSupport::TestCase
    VALID_ANALYSIS = {
      'classification' => 'informational',
      'urgency' => 'low',
      'needs_action' => false,
      'fixes' => [],
      'other_suggestions' => []
    }.freeze

    Response = Struct.new(:code, :body, keyword_init: true) do
      def is_a?(klass)
        klass == Net::HTTPSuccess && code.to_i == 200
      end
    end

    def setup
      @entry = log_entries(:pending_warning)
      @client = Client.new(
        endpoint: 'https://example.test/analyze',
        api_key: 'secret',
        model: 'primary-model',
        fallback_model: 'backup-model',
        prompt: 'Analyze this log entry.'
      )
    end

    test 'retries with fallback model when primary model is unavailable' do
      models_used = []
      stub_perform_request(@client, models_used) do |model_name|
        if model_name == 'primary-model'
          Response.new(code: '404', body: 'model primary-model not found')
        else
          Response.new(code: '200', body: { 'analysis' => VALID_ANALYSIS }.to_json)
        end
      end

      result = @client.analyze(@entry)

      assert_equal %w[primary-model backup-model], models_used
      assert_equal 'informational', result.classification
    end

    test 'does not retry fallback for non-model errors' do
      models_used = []
      stub_perform_request(@client, models_used) do |_model_name|
        Response.new(code: '500', body: 'internal error')
      end

      error = assert_raises Client::Error do
        @client.analyze(@entry)
      end

      assert_equal %w[primary-model], models_used
      assert_match(/500/, error.message)
    end

    test 'raises when both primary and fallback models are unavailable' do
      models_used = []
      stub_perform_request(@client, models_used) do |model_name|
        Response.new(code: '404', body: "model #{model_name} not found")
      end

      error = assert_raises Client::Error do
        @client.analyze(@entry)
      end

      assert_equal %w[primary-model backup-model], models_used
      assert_match(/backup-model/, error.message)
    end

    test 'skips duplicate fallback when it matches the primary model' do
      client = Client.new(
        endpoint: 'https://example.test/analyze',
        api_key: 'secret',
        model: 'same-model',
        fallback_model: 'same-model',
        prompt: 'Analyze this log entry.'
      )
      models_used = []
      stub_perform_request(client, models_used) do |_model_name|
        Response.new(code: '404', body: 'model not found')
      end

      assert_raises Client::Error do
        client.analyze(@entry)
      end

      assert_equal %w[same-model], models_used
    end

    private

    def stub_perform_request(client, models_used)
      client.define_singleton_method(:perform_request) do |_log_entry, model_name|
        models_used << model_name
        yield(model_name)
      end
    end
  end
end
