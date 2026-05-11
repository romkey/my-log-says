# frozen_string_literal: true

# Stores a deduplicated Docker log entry and its inference analysis state.
class LogEntry < ApplicationRecord
  STATUSES = %w[pending analyzing analyzed failed].freeze

  validates :source_container, :stream, :message, :fingerprint, presence: true
  validates :fingerprint, uniqueness: true
  validates :analysis_status, inclusion: { in: STATUSES }
  validates :occurrence_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :recent, -> { order(last_seen_at: :desc, created_at: :desc) }
  scope :needs_analysis, -> { where(analysis_status: %w[pending failed]) }

  def duplicate?
    occurrence_count > 1
  end

  def analyzed?
    analysis_status == 'analyzed'
  end
end
