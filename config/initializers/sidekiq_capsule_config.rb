# frozen_string_literal: true

# Thread pool defaults for Sidekiq capsules (analysis vs ingestion).
module SidekiqCapsuleConfig
  DEFAULTS = {
    'SIDEKIQ_DEFAULT_CONCURRENCY' => 1,
    'SIDEKIQ_ANALYSIS_CONCURRENCY' => 2,
    'SIDEKIQ_INGESTION_CONCURRENCY' => 2
  }.freeze

  def self.thread_count(key)
    fallback = DEFAULTS.fetch(key)
    value = ENV.fetch(key, fallback).to_i
    value.positive? ? value : fallback
  end
end
