# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module MyLogSays
  # Rails application configuration for MyLogSays.
  class Application < Rails::Application
    config.load_defaults 8.1

    config.active_job.queue_adapter = :sidekiq
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
