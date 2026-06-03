# frozen_string_literal: true

module LogEntries
  # Creates new log entries or updates existing duplicates by fingerprint.
  class Ingestor
    Result = Data.define(:log_entry, :duplicate)

    def self.call(**attributes)
      new(**attributes).call
    end

    def initialize(**attributes)
      @source_container = attributes.fetch(:source_container)
      @message = attributes.fetch(:message)
      @stream = attributes.fetch(:stream, 'stdout')
      @observed_at = attributes.fetch(:observed_at, Time.current)
      @raw_payload = attributes.fetch(:raw_payload, {})
      @enqueue_analysis = attributes.fetch(:enqueue_analysis, true)
    end

    def call
      result = upsert_log_entry

      AnalyzeLogEntryJob.perform_later(result.log_entry.id) if should_enqueue_analysis?(result)

      result
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    attr_reader :source_container, :message, :stream, :observed_at, :raw_payload, :enqueue_analysis

    def fingerprint
      @fingerprint ||= Fingerprint.call(source_container: source_container, stream: stream, message: message)
    end

    def upsert_log_entry
      LogEntry.transaction do
        log_entry = LogEntry.lock.find_by(fingerprint: fingerprint)
        return Result.new(log_entry: update_duplicate(log_entry), duplicate: true) if log_entry

        Result.new(log_entry: create_log_entry, duplicate: false)
      end
    end

    def update_duplicate(log_entry)
      log_entry.tap do |entry|
        entry.update!(
          occurrence_count: entry.occurrence_count + 1,
          last_seen_at: observed_at,
          raw_payload: raw_payload
        )
      end
    end

    def create_log_entry
      LogEntry.create!(log_entry_attributes)
    end

    def log_entry_attributes
      {
        source_container: source_container,
        stream: stream,
        message: message,
        fingerprint: fingerprint,
        occurrence_count: 1
      }.merge(log_entry_state_attributes)
    end

    def log_entry_state_attributes
      {
        first_seen_at: observed_at,
        last_seen_at: observed_at,
        raw_payload: raw_payload,
        analysis_status: analysis_status_for_container
      }
    end

    def analysis_status_for_container
      return 'excluded' if DockerContainers::AnalysisExclusion.skipped?(source_container)

      'pending'
    end

    def should_enqueue_analysis?(result)
      enqueue_analysis && !result.duplicate && result.log_entry.analysis_status == 'pending'
    end
  end
end
