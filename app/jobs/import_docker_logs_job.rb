# frozen_string_literal: true

# Imports recent Docker logs for a tracked container via the Docker Engine API.
class ImportDockerLogsJob < ApplicationJob
  queue_as :ingestion

  def perform(docker_container_id)
    container = DockerContainer.find(docker_container_id)
    container.mark_importing!

    result = DockerLogs::Importer.call(docker_container: container)
    container.mark_import_succeeded!(log_cursor_at: result.log_cursor_at)
  rescue DockerLogs::Importer::Error => e
    container&.mark_import_failed!(e.message)
  end
end
