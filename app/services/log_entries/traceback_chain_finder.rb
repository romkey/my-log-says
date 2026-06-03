# frozen_string_literal: true

module LogEntries
  # Finds adjacent log entry chains that should be merged into one traceback row.
  class TracebackChainFinder
    def self.call(entries)
      new(entries).call
    end

    def initialize(entries)
      @entries = entries
    end

    def call
      chains = []
      consumed = Set.new

      chains.concat(chains_from_primaries(consumed))
      chains.concat(chains_from_orphan_continuations(consumed))
      chains
    end

    private

    attr_reader :entries

    def chains_from_primaries(consumed)
      entries.each_with_index.filter_map do |entry, index|
        next if consumed.include?(entry.id)
        next unless DockerLogs::LogLineClassifier.primary_line?(entry.message)

        chain = build_forward_chain(index)
        next if chain.size <= 1

        chain.each { |member| consumed << member.id }
        chain
      end
    end

    def build_forward_chain(start_index)
      collect_continuations([entries[start_index]], start_index + 1, false)
    end

    def chains_from_orphan_continuations(consumed)
      chains = []
      index = 0

      while index < entries.size
        index, chain = next_orphan_chain(index, consumed)
        chains << chain if chain&.size.to_i > 1
      end

      chains
    end

    def next_orphan_chain(index, consumed)
      entry = entries[index]
      return [index + 1, nil] if consumed.include?(entry.id)
      return [index + 1, nil] unless orphan_continuation_start?(entry)

      chain = collect_continuations([], index, false)
      chain.each { |member| consumed << member.id }
      [index + chain.size, chain]
    end

    def orphan_continuation_start?(entry)
      !DockerLogs::LogLineClassifier.primary_line?(entry.message) &&
        DockerLogs::LogLineClassifier.continuation_line?(entry.message, traceback_open: false)
    end

    def collect_continuations(chain, offset, traceback_open)
      return chain if offset >= entries.size

      entry = entries[offset]
      return chain if DockerLogs::LogLineClassifier.primary_line?(entry.message)
      return chain unless DockerLogs::LogLineClassifier.continuation_line?(
        entry.message, traceback_open: traceback_open
      )

      collect_continuations(chain + [entry], offset + 1, true)
    end
  end
end
