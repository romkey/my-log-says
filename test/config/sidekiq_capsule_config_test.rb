# frozen_string_literal: true

require 'test_helper'

class SidekiqCapsuleConfigTest < ActiveSupport::TestCase
  setup do
    @original = {}
    SidekiqCapsuleConfig::DEFAULTS.each_key do |key|
      @original[key] = ENV.fetch(key, nil)
      ENV.delete(key)
    end
  end

  teardown do
    SidekiqCapsuleConfig::DEFAULTS.each_key do |key|
      if @original[key].nil?
        ENV.delete(key)
      else
        ENV[key] = @original[key]
      end
    end
  end

  test 'defaults give each queue its own thread budget' do
    assert_equal 1, SidekiqCapsuleConfig.thread_count('SIDEKIQ_DEFAULT_CONCURRENCY')
    assert_equal 2, SidekiqCapsuleConfig.thread_count('SIDEKIQ_ANALYSIS_CONCURRENCY')
    assert_equal 2, SidekiqCapsuleConfig.thread_count('SIDEKIQ_INGESTION_CONCURRENCY')
  end

  test 'reads overrides from the environment' do
    ENV['SIDEKIQ_ANALYSIS_CONCURRENCY'] = '6'

    assert_equal 6, SidekiqCapsuleConfig.thread_count('SIDEKIQ_ANALYSIS_CONCURRENCY')
  end
end
