# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class CanonicalMergerTest < ActiveSupport::TestCase
    test 'merges pending duplicate into analyzed canonical' do
      canonical = PrefixDuplicateTestHelper.analyzed_canonical(log_entries(:pending_warning))
      canonical.update!(occurrence_count: 2)
      duplicate = PrefixDuplicateTestHelper.prefix_duplicate_for(
        canonical,
        message: "2026-06-03T00:08:58.223Z INFO #{PrefixDuplicateTestHelper::CORE}",
        fingerprint_prefix: 'duplicate'
      )
      duplicate.update!(occurrence_count: 3)

      result = CanonicalMerger.call(duplicate)

      assert_equal canonical.id, result.canonical.id
      assert_equal 1, result.merged_count
      assert_not result.analyze_needed
      assert_equal 5, result.canonical.occurrence_count
      assert_not LogEntry.exists?(duplicate.id)
    end

    test 'merges two pending entries and keeps analysis needed' do
      first = log_entries(:pending_warning)
      first.update!(normalized_message: PrefixDuplicateTestHelper::CORE, message: PrefixDuplicateTestHelper::CORE)
      second = PrefixDuplicateTestHelper.prefix_duplicate_for(
        first,
        message: "[12345] #{PrefixDuplicateTestHelper::CORE}",
        fingerprint_prefix: 'second'
      )

      result = CanonicalMerger.call(second)

      assert_equal first.id, result.canonical.id
      assert_equal 1, result.merged_count
      assert result.analyze_needed
      assert_not LogEntry.exists?(second.id)
    end
  end
end
