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

      log_entry.update!(analysis_status: 'analyzing', analysis_error: nil)
      analysis = client.analyze(log_entry)
      log_entry.update!(analysis: analysis, analysis_status: 'analyzed', analyzed_at: Time.current)
      log_entry
    rescue Inference::Client::Error => e
      log_entry.update!(analysis_status: 'failed', analysis_error: e.message)
      raise
    end

    private

    attr_reader :log_entry, :client
  end
end
