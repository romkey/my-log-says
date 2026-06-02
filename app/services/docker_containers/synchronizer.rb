# frozen_string_literal: true

module DockerContainers
  # Discovers containers from Docker and upserts local records.
  class Synchronizer
    Result = Data.define(:containers, :deactivated_count)

    def self.call(client: Docker::Client.new)
      new(client: client).call
    end

    def initialize(client:)
      @client = client
    end

    def call
      remote_containers = client.list_containers(all: true)
      seen_ids = remote_containers.map { |remote| upsert_container(remote).docker_id }

      deactivated_count = deactivate_missing(seen_ids)

      Result.new(containers: DockerContainer.active.order(:name), deactivated_count: deactivated_count)
    end

    private

    attr_reader :client

    def upsert_container(remote)
      attributes = {
        name: container_name(remote),
        image: remote['Image'],
        state: remote['State'],
        active: true
      }

      DockerContainer.find_or_initialize_by(docker_id: remote['Id']).tap do |container|
        container.assign_attributes(attributes)
        container.save!
      end
    end

    def container_name(remote)
      Array(remote['Names']).first.to_s.delete_prefix('/').presence || remote['Id'].first(12)
    end

    def deactivate_missing(seen_ids)
      scope = DockerContainer.active
      scope = scope.where.not(docker_id: seen_ids) if seen_ids.any?
      count = scope.count
      scope.find_each { |container| container.update!(active: false, state: 'removed') }
      count
    end
  end
end
