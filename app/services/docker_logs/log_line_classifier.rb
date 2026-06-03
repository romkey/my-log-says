# frozen_string_literal: true

module DockerLogs
  # Classifies log line bodies as primary records or traceback continuations.
  class LogLineClassifier
    # Primary-line patterns mirror LogEntries::MessageNormalizer prefixes (Home Assistant adds its own).
    # rubocop:disable Style/RegexpLiteral, Style/RedundantRegexpEscape
    HOME_ASSISTANT_PRIMARY = /
      \A\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+\s+
      (?:DEBUG|INFO|WARNING|WARN|ERROR|CRITICAL)\b
    /x
    ISO_PRIMARY = %r{
      \A[\[\("']?
      \d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?
      [\]\)"']?\s+
    }x
    SYSLOG_PRIMARY = /
      \A(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+
      \d{1,2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?\s+
    /ix
    LOG_LEVEL_PRIMARY = /\A(?:DEBUG|INFO|WARN|WARNING|ERROR|FATAL|TRACE|CRITICAL)\b/ix
    # rubocop:enable Style/RegexpLiteral, Style/RedundantRegexpEscape

    PRIMARY_PATTERNS = [
      HOME_ASSISTANT_PRIMARY,
      ISO_PRIMARY,
      SYSLOG_PRIMARY,
      LOG_LEVEL_PRIMARY
    ].freeze

    TRACEBACK_CONTINUATIONS = [
      /\ATraceback \(most recent call last\):/,
      /\A\s*File "/,
      /\A\s*\.\.\.<\d+ lines>\.\.\./,
      /\A\s*\^+\s*\z/,
      /\AThe above exception was the direct cause/i,
      /\ADuring handling of the following exception/i,
      /\ACaused by:/i,
      /\A\s*at /,
      /\A[A-Z][A-Za-z0-9_.]+(?:Error|Exception):?\s*\z/,
      /\A(?:TimeoutError|CancelledError|KeyboardInterrupt)\s*\z/
    ].freeze

    def self.primary_line?(body)
      return false if body.blank?

      PRIMARY_PATTERNS.any? { |pattern| pattern.match?(body) }
    end

    def self.continuation_line?(body, traceback_open:)
      return traceback_open if body.blank?

      TRACEBACK_CONTINUATIONS.any? { |pattern| pattern.match?(body) }
    end
  end
end
