# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class TracebackChainMergerTest < ActiveSupport::TestCase
    HA_WARNING = '2026-06-03 07:01:31.838 WARNING (MainThread) [bond.entity] Entity unavailable'

    setup do
      @container = 'home-assistant'
      @stream = 'stderr'
      @base_time = Time.zone.parse('2026-06-03T07:01:31Z')
    end

    test 'merges traceback chain rows into one entry' do
      primary = create_split_entry(HA_WARNING, offset: 0)
      create_split_entry('Traceback (most recent call last):', offset: 1)
      create_split_entry('File "/bond/entity.py", line 142, in _async_update', offset: 2)
      create_split_entry('TimeoutError', offset: 3)

      result = TracebackChainMerger.call

      assert_equal 1, result.chains
      assert_equal 3, result.merged_rows
      assert_equal 1, LogEntry.where(source_container: @container).count

      merged = LogEntry.find(primary.id)

      assert_includes merged.message, HA_WARNING
      assert_includes merged.message, 'Traceback (most recent call last):'
      assert_includes merged.message, 'TimeoutError'
      assert_equal 4, merged.occurrence_count
    end

    test 'dry run reports chains without changing rows' do
      create_split_entry(HA_WARNING, offset: 0)
      create_split_entry('Traceback (most recent call last):', offset: 1)
      create_split_entry('TimeoutError', offset: 2)

      assert_no_difference -> { LogEntry.count } do
        result = TracebackChainMerger.call(dry_run: true)

        assert_equal 1, result.chains
        assert_equal 2, result.merged_rows
        assert result.dry_run
      end
    end

    test 'does not merge unrelated lines without traceback shape' do
      create_split_entry(HA_WARNING, offset: 0)
      create_split_entry('continued narrative line without traceback shape', offset: 1)

      result = TracebackChainMerger.call

      assert_equal 0, result.chains
      assert_equal 2, LogEntry.where(source_container: @container).count
    end

    private

    def create_split_entry(message, offset:)
      LogEntry.create!(split_entry_attrs(message, offset))
    end

    def split_entry_attrs(message, offset)
      seen_at = @base_time + offset.seconds
      {
        source_container: @container, stream: @stream, message: message,
        normalized_message: Fingerprint.normalized_message_for(message),
        fingerprint: "traceback-chain-test-#{message.hash}-#{offset}",
        first_seen_at: seen_at, last_seen_at: seen_at, analysis_status: 'pending'
      }
    end
  end
end
