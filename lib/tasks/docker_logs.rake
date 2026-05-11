# frozen_string_literal: true

namespace :docker_logs do
  desc 'Import Docker logs for CONTAINER'
  task import: :environment do
    container = ENV.fetch('CONTAINER')
    result = DockerLogs::Importer.call(container_name: container)

    puts "Imported #{result.imported_count} log lines (#{result.duplicate_count} duplicates)"
  end
end
