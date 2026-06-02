# frozen_string_literal: true

module DockerContainers
  # Discovers containers from Docker and upserts local records.
  class Synchronizer
    Result = Data.define(:containers, :deactivated_count, :excluded_count)

    def self.call(client: Docker::Client.new)
      new(client: client).call
    end

    def initialize(client:)
      @client = client
    end

    def call
      seen_ids, excluded_count = sync_remote_containers(client.list_containers(all: true))

      Result.new(
        containers: DockerContainer.importable.order(:name),
        deactivated_count: deactivate_missing(seen_ids),
        excluded_count: excluded_count
      )
    end

    def sync_remote_containers(remote_containers)
      excluded_count = 0
      seen_ids = remote_containers.map do |remote|
        container = upsert_container(remote)
        excluded_count += 1 if container.import_status == 'excluded'
        container.docker_id
      end
      [seen_ids, excluded_count]
    end

    private

    attr_reader :client

    def upsert_container(remote)
      if ImportSkipper.skip?(remote)
        upsert_excluded_container(remote)
      else
        upsert_importable_container(remote)
      end
    end

    def upsert_excluded_container(remote)
      upsert_record(remote, active: false, import_status: 'excluded', import_error: nil)
    end

    def upsert_importable_container(remote)
      DockerContainer.find_or_initialize_by(docker_id: remote['Id']).tap do |container|
        was_excluded = container.import_status == 'excluded'
        assign_remote_attributes(container, remote, active: true)
        container.import_status = 'idle' if container.new_record? || was_excluded
        container.save!
      end
    end

    def upsert_record(remote, active:, import_status:, import_error:)
      DockerContainer.find_or_initialize_by(docker_id: remote['Id']).tap do |container|
        assign_remote_attributes(container, remote, active: active)
        container.import_status = import_status
        container.import_error = import_error
        container.save!
      end
    end

    def assign_remote_attributes(container, remote, active:)
      container.assign_attributes(
        name: container_name(remote),
        image: remote['Image'],
        state: remote['State'],
        active: active
      )
    end

    def container_name(remote)
      Array(remote['Names']).first.to_s.delete_prefix('/').presence || remote['Id'].first(12)
    end

    def deactivate_missing(seen_ids)
      scope = DockerContainer.where(active: true)
      scope = scope.where.not(docker_id: seen_ids) if seen_ids.any?
      count = scope.count
      scope.find_each { |container| container.update!(active: false, state: 'removed') }
      count
    end
  end
end
