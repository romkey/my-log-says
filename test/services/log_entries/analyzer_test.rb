# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class AnalyzerTest < ActiveSupport::TestCase
    SAMPLE_RESULT = Inference::AnalysisResult.new(
      classification: 'connectivity',
      urgency: 'high',
      needs_action: true,
      fixes: ['Investigate upstream retries.'],
      other_suggestions: ['Review rate limits.']
    )

    FakeClient = Data.define(:result) do
      def analyze(_log_entry)
        result
      end
    end

    FailingClient = Class.new do
      def analyze(_log_entry)
        raise Inference::Client::Error, 'server unavailable'
      end
    end

    test 'stores structured analysis returned by inference client' do
      entry = log_entries(:pending_warning)

      Analyzer.call(entry, client: FakeClient.new(SAMPLE_RESULT))

      entry.reload
      assert_equal 'analyzed', entry.analysis_status
      assert_equal 'connectivity', entry.classification
      assert_equal 'high', entry.urgency
      assert entry.needs_action?
      assert_equal ['Investigate upstream retries.'], entry.fixes
      assert_equal ['Review rate limits.'], entry.other_suggestions
      assert_not_nil entry.analyzed_at
    end

    test 'does not re-analyze an already analyzed entry' do
      entry = log_entries(:analyzed_error)

      Analyzer.call(entry, client: FailingClient.new)

      assert_equal 'analyzed', entry.reload.analysis_status
      assert_equal 'connectivity', entry.classification
    end

    test 'marks analysis failures for retry' do
      entry = log_entries(:pending_warning)

      assert_raises Inference::Client::Error do
        Analyzer.call(entry, client: FailingClient.new)
      end

      assert_equal 'failed', entry.reload.analysis_status
      assert_equal 'server unavailable', entry.analysis_error
    end
  end
end
