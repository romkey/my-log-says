# frozen_string_literal: true

module LogEntries
  # Coordinates inference analysis for a single log entry.
  class Analyzer
    def self.call(log_entry, client: Inference::Client.new)
      new(log_entry, client: client).call
    end

    def initialize(log_entry, client: Inference::Client.new)
      @log_entry = log_entry
      @client = client
    end

    def call
      return log_entry if log_entry.analyzed?

      mark_analyzing!
      save_success!(client.analyze(log_entry))
    rescue Inference::Client::Error => e
      mark_failed!(e)
      raise if e.is_a?(Inference::Client::RetryableError)
    end

    private

    attr_reader :log_entry, :client

    def mark_analyzing!
      log_entry.update!(analysis_status: 'analyzing', analysis_error: nil)
    end

    def save_success!(result)
      log_entry.update!(
        result.to_log_entry_attributes.merge(
          analysis_status: 'analyzed',
          analyzed_at: Time.current
        )
      )
      log_entry
    end

    def mark_failed!(error)
      log_entry.update!(analysis_status: 'failed', analysis_error: error.message)
    end
  end
end
