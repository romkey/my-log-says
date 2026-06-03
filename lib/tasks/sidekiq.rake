# frozen_string_literal: true

namespace :sidekiq do
  desc 'Clear queued, retry, scheduled, and dead Sidekiq jobs (use after resetting the database)'
  task clear_queues: :environment do
    require 'sidekiq/api'

    Sidekiq::Queue.find_each(&:clear)
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::DeadSet.new.clear

    puts 'Cleared Sidekiq queues'
  end
end
