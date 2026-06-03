# frozen_string_literal: true

module LogEntries
  # Collapses prefix-variant log entries into a single canonical row.
  class CanonicalMerger
    Result = Data.define(:canonical, :merged_count, :analyze_needed)

    CANONICAL_STATUS_ORDER = {
      'analyzed' => 0,
      'failed' => 1,
      'analyzing' => 2,
      'pending' => 3,
      'excluded' => 4
    }.freeze

    def self.call(log_entry = nil)
      new(log_entry).call
    end

    def initialize(log_entry = nil)
      @log_entry = log_entry
    end

    def call
      return merge_all_groups if log_entry.nil?

      merge_group(matching_entries(log_entry))
    end

    private

    attr_reader :log_entry

    def merge_all_groups
      totals = { groups: 0, merged: 0 }
      grouped_keys.each do |source_container, stream, normalized_message|
        sample = LogEntry.find_by!(
          source_container: source_container,
          stream: stream,
          normalized_message: normalized_message
        )
        result = merge_group(matching_entries(sample))
        next if result.merged_count.zero?

        totals[:groups] += 1
        totals[:merged] += result.merged_count
      end
      totals
    end

    def grouped_keys
      LogEntry
        .group(:source_container, :stream, :normalized_message)
        .having('COUNT(*) > 1')
        .count
        .keys
    end

    def matching_entries(entry)
      LogEntry.where(
        source_container: entry.source_container,
        stream: entry.stream,
        normalized_message: entry.normalized_message
      ).order(:id)
    end

    def merge_group(entries)
      entries = entries.to_a
      return single_result(entries.first) if entries.size <= 1

      canonical = pick_canonical(entries)
      duplicates = entries.reject { |entry| entry.id == canonical.id }
      merge_duplicates!(canonical, duplicates)

      Result.new(
        canonical: canonical.reload,
        merged_count: duplicates.size,
        analyze_needed: analyze_needed?(canonical)
      )
    end

    def single_result(entry)
      Result.new(
        canonical: entry,
        merged_count: 0,
        analyze_needed: analyze_needed?(entry)
      )
    end

    def pick_canonical(entries)
      entries.min_by do |entry|
        [
          CANONICAL_STATUS_ORDER.fetch(entry.analysis_status, 99),
          canonical_tiebreaker(entry),
          entry.id
        ]
      end
    end

    def canonical_tiebreaker(entry)
      return -entry.occurrence_count if entry.analysis_status == 'analyzed'

      0
    end

    def merge_duplicates!(canonical, duplicates)
      LogEntry.transaction do
        canonical.lock!
        canonical.update!(
          occurrence_count: canonical.occurrence_count + duplicates.sum(&:occurrence_count),
          last_seen_at: [canonical.last_seen_at, *duplicates.map(&:last_seen_at)].max
        )
        duplicates.each(&:destroy!)
      end
    end

    def analyze_needed?(entry)
      entry.analysis_status == 'pending' && !DockerContainers::AnalysisExclusion.skipped?(entry.source_container)
    end
  end
end
