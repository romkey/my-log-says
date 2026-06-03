# frozen_string_literal: true

module PrefixDuplicateTestHelper
  CORE = 'Retrying failed request'

  module_function

  def analyzed_canonical(entry)
    entry.update!(
      analysis_status: 'analyzed',
      classification: 'informational',
      urgency: 'low',
      needs_action: false,
      fixes: [],
      other_suggestions: [],
      normalized_message: CORE
    )
    entry
  end

  def prefix_duplicate_for(entry, message:, fingerprint_prefix:)
    LogEntry.create!(
      source_container: entry.source_container,
      stream: entry.stream,
      message: message,
      normalized_message: CORE,
      fingerprint: "#{fingerprint_prefix}-#{SecureRandom.hex(4)}",
      occurrence_count: 1,
      first_seen_at: Time.current,
      last_seen_at: Time.current,
      analysis_status: 'pending',
      raw_payload: {}
    )
  end
end
