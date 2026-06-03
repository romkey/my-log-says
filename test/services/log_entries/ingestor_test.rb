# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class IngestorTest < ActiveJob::TestCase
    setup do
      clear_enqueued_jobs
      @observed_at = Time.zone.parse('2026-05-10 20:30:00')
    end

    test 'creates a new log entry and queues analysis' do
      assert_difference -> { LogEntry.count }, 1 do
        assert_enqueued_with(job: AnalyzeLogEntryJob) do
          result = Ingestor.call(
            source_container: 'web',
            stream: 'stderr',
            message: 'database timeout',
            observed_at: @observed_at
          )

          assert_not result.duplicate
          assert_equal 1, result.log_entry.occurrence_count
          assert_equal 'pending', result.log_entry.analysis_status
        end
      end
    end

    test 'does not enqueue analysis for excluded containers' do
      docker_containers(:web).exclude_from_analysis!

      assert_no_enqueued_jobs do
        result = Ingestor.call(
          source_container: 'web',
          stream: 'stderr',
          message: 'ignored noise',
          observed_at: @observed_at
        )

        assert_not result.duplicate
        assert_equal 'excluded', result.log_entry.analysis_status
      end
    end

    test 'counts duplicates without queueing another analysis' do
      first = Ingestor.call(
        source_container: 'web',
        stream: 'stderr',
        message: 'database timeout',
        observed_at: @observed_at
      )
      clear_enqueued_jobs

      assert_no_enqueued_jobs do
        result = Ingestor.call(
          source_container: ' web ',
          stream: 'STDERR',
          message: ' database timeout ',
          observed_at: @observed_at + 1.minute
        )

        assert result.duplicate
        assert_equal first.log_entry.id, result.log_entry.id
        assert_equal 2, result.log_entry.reload.occurrence_count
        assert_equal @observed_at + 1.minute, result.log_entry.last_seen_at
      end
    end
  end
end
