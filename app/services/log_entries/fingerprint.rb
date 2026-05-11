# frozen_string_literal: true

require 'digest'

module LogEntries
  # Generates stable fingerprints used to detect duplicate log entries.
  class Fingerprint
    def self.call(source_container:, stream:, message:)
      normalized = [
        source_container.to_s.strip,
        stream.to_s.strip.downcase,
        message.to_s.strip
      ].join("\0")

      Digest::SHA256.hexdigest(normalized)
    end
  end
end
