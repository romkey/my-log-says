# frozen_string_literal: true

module DockerContainers
  # Finds or creates a container record and toggles LLM analysis for it.
  class AnalysisExclusion
    def self.skipped?(container_name)
      DockerContainer.exists?(name: container_name, skip_analysis: true)
    end

    def self.flip(container_name:)
      container = find_or_create_by_name(container_name)
      container.skip_analysis? ? container.include_in_analysis! : container.exclude_from_analysis!
      container
    end

    def self.find_or_create_by_name(name)
      DockerContainer.find_by(name: name) || DockerContainer.create!(
        docker_id: synthetic_docker_id(name),
        name: name,
        active: false,
        import_status: 'idle'
      )
    end

    def self.synthetic_docker_id(name)
      "manual-#{Digest::SHA256.hexdigest(name)}"
    end

    private_class_method :synthetic_docker_id
  end
end
