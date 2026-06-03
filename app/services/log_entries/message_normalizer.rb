# frozen_string_literal: true

module LogEntries
  # Strips variable timestamp/PID/log-level prefixes from the start of log lines.
  class MessageNormalizer
    MAX_PASSES = 10

    ISO_TIMESTAMP = %r{
      \A[\[\("']?
      \d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?
      [\]\)"']?\s+
    }x
    SYSLOG_TIMESTAMP = %r{
      \A(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+
      \d{1,2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?\s+
    }ix
    BRACKETED_PID = %r{\A[\[\("']\d{1,7}[\]\)"']\s+}x
    BARE_PID = %r{\A\d{4,7}(?=\s+\D)\s+}x
    LOG_LEVEL = %r{
      \A(?:DEBUG|INFO|WARN|WARNING|ERROR|FATAL|TRACE)
      (?:\s+\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)?
      \s+
    }ix
    SIDEKIQ_METADATA = /\A(?:pid=\d+\s+)(?:tid=\S+\s+)?(?:jid=\S+\s+)?/

    PREFIX_PATTERNS = [
      ISO_TIMESTAMP,
      SYSLOG_TIMESTAMP,
      BRACKETED_PID,
      BARE_PID,
      LOG_LEVEL,
      SIDEKIQ_METADATA
    ].freeze

    def self.call(message)
      new(message).normalize
    end

    def initialize(message)
      @message = message.to_s.strip
    end

    def normalize
      return message if message.blank?

      normalized = message
      MAX_PASSES.times do
        stripped = strip_once(normalized)
        break if stripped == normalized

        normalized = stripped
      end

      normalized.presence || message
    end

    private

    attr_reader :message

    def strip_once(text)
      PREFIX_PATTERNS.each do |pattern|
        next unless pattern.match?(text)

        return text.sub(pattern, '')
      end

      text
    end
  end
end
