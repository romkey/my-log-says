# frozen_string_literal: true

require 'test_helper'

module Inference
  class PromptTest < ActiveSupport::TestCase
    test 'uses INFERENCE_PROMPT when set' do
      with_env('INFERENCE_PROMPT' => 'Custom instructions') do
        assert_equal 'Custom instructions', Prompt.resolve
      end
    end

    test 'uses inference prompt stored in the database' do
      with_env('INFERENCE_PROMPT' => nil) do
        inference_settings(:default).update!(inference_prompt: 'Stored prompt with classification.')

        assert_equal 'Stored prompt with classification.', Prompt.resolve
      end
    end

    test 'falls back to example prompt file when database is empty' do
      with_env('INFERENCE_PROMPT' => nil, 'INFERENCE_PROMPT_FILE' => nil) do
        InferenceSetting.delete_all

        assert_includes Prompt.resolve, 'classification'
      end
    end

    private

    def with_env(overrides)
      previous = overrides.keys.index_with { |key| ENV.fetch(key, nil) }
      overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
