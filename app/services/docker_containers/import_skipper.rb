# frozen_string_literal: true

module DockerContainers
  # Decides whether a Docker container should be excluded from log import.
  class ImportSkipper
    SKIP_LABEL = 'loglady.io/skip-log-import'
    DEFAULT_IMAGE_SUBSTRINGS = %w[loglady ghcr.io/romkey/loglady].freeze
    DEFAULT_NAME_SUBSTRINGS = %w[loglady log-lady].freeze

    def self.skip?(remote)
      new.skip?(remote)
    end

    def skip?(remote)
      return false unless skip_self_enabled?

      label_skipped?(remote) ||
        compose_project_skipped?(remote) ||
        image_skipped?(remote) ||
        name_skipped?(remote)
    end

    private

    def skip_self_enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('DOCKER_LOG_SKIP_SELF', 'true'))
    end

    def label_skipped?(remote)
      remote.dig('Labels', SKIP_LABEL).to_s == 'true'
    end

    def compose_project_skipped?(remote)
      project = ENV['LOGLADY_COMPOSE_PROJECT'].to_s.strip
      return false if project.blank?

      remote.dig('Labels', 'com.docker.compose.project') == project
    end

    def image_skipped?(remote)
      image = remote['Image'].to_s.downcase
      image_patterns.any? { |pattern| image.include?(pattern.downcase) }
    end

    def name_skipped?(remote)
      name = Array(remote['Names']).first.to_s.delete_prefix('/').downcase
      name_patterns.any? { |pattern| name.include?(pattern.downcase) }
    end

    def image_patterns
      @image_patterns ||= env_patterns('DOCKER_LOG_EXCLUDE_IMAGES', DEFAULT_IMAGE_SUBSTRINGS)
    end

    def name_patterns
      @name_patterns ||= env_patterns('DOCKER_LOG_EXCLUDE_NAMES', DEFAULT_NAME_SUBSTRINGS)
    end

    def env_patterns(key, defaults)
      value = ENV.fetch(key, defaults.join(',')).split(',').map(&:strip).compact_blank
      value.presence || defaults
    end
  end
end
