# frozen_string_literal: true

# Discovers Docker containers and enqueues log import for each active container.
class SyncDockerContainersJob < ApplicationJob
  queue_as :ingestion

  def perform
    result = DockerContainers::Synchronizer.call

    result.containers.find_each do |container|
      ImportDockerLogsJob.perform_later(container.id)
    end
  rescue Docker::Client::Error => e
    Rails.logger.error("[SyncDockerContainersJob] #{e.message}")
  end
end
