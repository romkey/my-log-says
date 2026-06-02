# frozen_string_literal: true

namespace :docker_logs do
  desc 'Import Docker logs for CONTAINER'
  task import: :environment do
    container_name = ENV.fetch('CONTAINER')
    sync = DockerContainers::Synchronizer.call
    docker_container = sync.containers.find { |container| container.name == container_name }
    docker_container ||= DockerContainer.find_by!(name: container_name)

    result = DockerLogs::Importer.call(docker_container: docker_container)

    puts "Imported #{result.imported_count} log lines (#{result.duplicate_count} duplicates)"
    puts "Line errors: #{result.line_errors.join(', ')}" if result.line_errors.any?
  end
end
