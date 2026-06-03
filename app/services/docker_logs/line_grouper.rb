# frozen_string_literal: true

module DockerLogs
  # Folds traceback continuation lines into the preceding primary log entry.
  class LineGrouper
    def self.call(entries, enabled: multiline_enabled?)
      return entries unless enabled

      new(entries).call
    end

    def self.multiline_enabled?
      ENV.fetch('DOCKER_LOG_GROUP_MULTILINE', 'true') != 'false'
    end

    def initialize(entries)
      @entries = entries
    end

    def call
      grouped = []
      current = nil
      traceback_open = false

      entries.each do |entry|
        current, traceback_open, grouped = process_entry(
          entry, current, traceback_open, grouped
        )
      end

      grouped << current if current
      grouped
    end

    private

    attr_reader :entries

    def process_entry(entry, current, traceback_open, grouped)
      body = entry.message

      if LogLineClassifier.primary_line?(body)
        grouped = append_current(grouped, current)
        return [entry, false, grouped]
      end

      if LogLineClassifier.continuation_line?(body, traceback_open: traceback_open) && current
        return [merge_entries(current, entry), true, grouped]
      end

      grouped = append_current(grouped, current)
      [nil, false, grouped + [entry]]
    end

    def append_current(grouped, current)
      current ? grouped + [current] : grouped
    end

    def merge_entries(current, entry)
      StreamDemuxer::Entry.new(
        stream: current.stream,
        timestamp: current.timestamp,
        message: [current.message, entry.message].join("\n"),
        observed_at: entry.observed_at
      )
    end
  end
end
