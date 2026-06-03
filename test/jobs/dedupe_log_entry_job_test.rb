# frozen_string_literal: true

require 'test_helper'

class DedupeLogEntryJobTest < ActiveJob::TestCase
  test 'enqueues analysis when canonical entry is pending' do
    entry = log_entries(:pending_warning)

    assert_enqueued_with(job: AnalyzeLogEntryJob, args: [entry.id]) do
      DedupeLogEntryJob.perform_now(entry.id)
    end
  end

  test 'skips analysis when duplicate merges into analyzed canonical' do
    canonical = PrefixDuplicateTestHelper.analyzed_canonical(log_entries(:pending_warning))
    duplicate = PrefixDuplicateTestHelper.prefix_duplicate_for(
      canonical,
      message: "[12345] #{PrefixDuplicateTestHelper::CORE}",
      fingerprint_prefix: 'dedupe'
    )

    assert_no_enqueued_jobs do
      DedupeLogEntryJob.perform_now(duplicate.id)
    end
  end
end
