# frozen_string_literal: true

# Imports recent Docker logs for a configured container.
class ImportDockerLogsJob < ApplicationJob
  queue_as :ingestion

  def perform(container_name)
    DockerLogs::Importer.call(container_name: container_name)
  end
end
