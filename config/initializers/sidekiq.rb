# frozen_string_literal: true

redis_url = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.concurrency = SidekiqCapsuleConfig.thread_count('SIDEKIQ_DEFAULT_CONCURRENCY')
  config.queues = %w[default]

  config.capsule('analysis') do |cap|
    cap.concurrency = SidekiqCapsuleConfig.thread_count('SIDEKIQ_ANALYSIS_CONCURRENCY')
    cap.queues = %w[analysis]
  end

  config.capsule('ingestion') do |cap|
    cap.concurrency = SidekiqCapsuleConfig.thread_count('SIDEKIQ_INGESTION_CONCURRENCY')
    cap.queues = %w[ingestion]
  end

  config.on(:startup) do
    if docker_log_sync_enabled?
      Sidekiq::Cron::Job.load_from_hash!(
        'docker_log_sync' => {
          'cron' => ENV.fetch('DOCKER_LOG_SYNC_CRON', '*/1 * * * *'),
          'class' => 'SyncDockerContainersJob',
          'active_job' => true
        }
      )
    else
      Sidekiq::Cron::Job.destroy('docker_log_sync')
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

def docker_log_sync_enabled?
  ActiveModel::Type::Boolean.new.cast(ENV.fetch('DOCKER_LOG_SYNC_ENABLED', 'true'))
end
