# frozen_string_literal: true

require 'digest'

module LogEntries
  # Generates stable fingerprints used to detect duplicate log entries.
  class Fingerprint
    def self.call(source_container:, stream:, message:)
      normalized_message = MessageNormalizer.call(message)
      normalized = [
        source_container.to_s.strip,
        stream.to_s.strip.downcase,
        normalized_message
      ].join("\0")

      Digest::SHA256.hexdigest(normalized)
    end

    def self.normalized_message_for(message)
      MessageNormalizer.call(message)
    end
  end
end
