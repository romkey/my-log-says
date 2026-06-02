# frozen_string_literal: true

module DockerLogs
  # Parses DOCKER_LOGS_SINCE values like 10m, 1h, and 30s into timestamps.
  class SinceParser
    PATTERN = /\A(\d+)([smhd])\z/
    UNITS = {
      's' => :seconds,
      'm' => :minutes,
      'h' => :hours,
      'd' => :days
    }.freeze

    def self.call(value)
      new(value).call
    end

    def initialize(value)
      @value = value.to_s.strip
    end

    def call
      match = value.match(PATTERN)
      return 10.minutes.ago unless match

      amount = match[1].to_i
      unit = UNITS[match[2]]
      return 10.minutes.ago unless unit

      amount.public_send(unit).ago
    end

    private

    attr_reader :value
  end
end
