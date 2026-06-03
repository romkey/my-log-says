# frozen_string_literal: true

namespace :log_entries do
  desc 'Backfill normalized messages, merge prefix-variant duplicates, and recompute fingerprints'
  task merge_prefix_duplicates: :environment do
    LogEntry.where(normalized_message: nil).find_each do |entry|
      entry.update!(normalized_message: LogEntries::Fingerprint.normalized_message_for(entry.message))
    end

    totals = LogEntries::CanonicalMerger.call

    LogEntry.find_each do |entry|
      normalized = LogEntries::Fingerprint.normalized_message_for(entry.message)
      fingerprint = LogEntries::Fingerprint.call(
        source_container: entry.source_container,
        stream: entry.stream,
        message: entry.message
      )
      entry.update!(normalized_message: normalized, fingerprint: fingerprint)
    end

    puts "Merged #{totals[:merged]} rows across #{totals[:groups]} duplicate groups."
  end
end
