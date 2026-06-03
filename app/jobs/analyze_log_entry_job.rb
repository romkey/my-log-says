# frozen_string_literal: true

# Sends a log entry to the configured inference service for analysis.
class AnalyzeLogEntryJob < ApplicationJob
  queue_as :analysis

  retry_on Inference::Client::RetryableError, wait: :polynomially_longer, attempts: 3

  def perform(log_entry_id)
    log_entry = LogEntry.find_by(id: log_entry_id)
    return unless log_entry
    return if log_entry.analysis_status == 'excluded'
    return if DockerContainers::AnalysisExclusion.skipped?(log_entry.source_container)

    LogEntries::Analyzer.call(log_entry)
  end
end
