# frozen_string_literal: true

# Finds prefix-variant duplicates and enqueues analysis only for canonical pending entries.
class DedupeLogEntryJob < ApplicationJob
  queue_as :analysis

  def perform(log_entry_id)
    log_entry = LogEntry.find_by(id: log_entry_id)
    return unless log_entry

    result = LogEntries::CanonicalMerger.call(log_entry)
    return unless result.analyze_needed

    AnalyzeLogEntryJob.perform_later(result.canonical.id)
  end
end
