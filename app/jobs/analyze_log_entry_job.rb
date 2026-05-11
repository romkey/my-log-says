# frozen_string_literal: true

# Sends a log entry to the configured inference service for analysis.
class AnalyzeLogEntryJob < ApplicationJob
  queue_as :analysis

  retry_on Inference::Client::Error, wait: :polynomially_longer, attempts: 3

  def perform(log_entry_id)
    LogEntries::Analyzer.call(LogEntry.find(log_entry_id))
  end
end
