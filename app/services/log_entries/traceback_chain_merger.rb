# frozen_string_literal: true

module LogEntries
  # Merges existing log rows that were ingested as separate traceback lines before multiline grouping.
  class TracebackChainMerger
    Result = Data.define(:chains, :merged_rows, :dry_run)

    def self.call(dry_run: false)
      new(dry_run: dry_run).call
    end

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    def call
      totals = { chains: 0, merged_rows: 0 }

      container_streams.each do |source_container, stream|
        totals = merge_chains_for(source_container, stream, totals)
      end

      Result.new(
        chains: totals[:chains],
        merged_rows: totals[:merged_rows],
        dry_run: dry_run
      )
    end

    private

    attr_reader :dry_run

    def container_streams
      LogEntry.distinct.order(:source_container, :stream).pluck(:source_container, :stream)
    end

    def merge_chains_for(source_container, stream, totals)
      entries = LogEntry.where(source_container: source_container, stream: stream).order(:id).to_a

      TracebackChainFinder.call(entries).each do |chain|
        totals[:chains] += 1
        totals[:merged_rows] += chain.size - 1
        merge_chain!(chain) unless dry_run
      end

      totals
    end

    def merge_chain!(chain)
      combined_message = chain.map { |entry| DockerLogs::LogLineClassifier.body(entry.message) }.join("\n")
      canonical = CanonicalMerger.pick_canonical(chain)
      duplicates = chain.reject { |entry| entry.id == canonical.id }
      fingerprint = fingerprint_for(canonical, combined_message)

      LogEntry.transaction do
        duplicates.each(&:destroy!)
        persist_merged_chain!(canonical, combined_message, chain, fingerprint)
      end
    end

    def persist_merged_chain!(canonical, combined_message, chain, fingerprint)
      existing = LogEntry.find_by(fingerprint: fingerprint)
      if existing && existing.id != canonical.id
        CanonicalMerger.merge_duplicates!(existing, [canonical.reload])
        return
      end

      canonical.reload.lock!
      canonical.update!(merged_attributes(combined_message, chain, fingerprint))
    end

    def merged_attributes(combined_message, chain, fingerprint)
      {
        message: combined_message,
        normalized_message: Fingerprint.normalized_message_for(combined_message),
        fingerprint: fingerprint,
        occurrence_count: chain.sum(&:occurrence_count),
        first_seen_at: chain.map(&:first_seen_at).min,
        last_seen_at: chain.map(&:last_seen_at).max
      }
    end

    def fingerprint_for(entry, message)
      Fingerprint.call(
        source_container: entry.source_container,
        stream: entry.stream,
        message: message
      )
    end
  end
end
