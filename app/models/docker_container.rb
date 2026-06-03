# frozen_string_literal: true

# Tracks a Docker container discovered via the Docker Engine API for log import.
class DockerContainer < ApplicationRecord
  IMPORT_STATUSES = %w[idle importing succeeded failed excluded].freeze

  validates :docker_id, :name, presence: true
  validates :docker_id, uniqueness: true
  validates :import_status, inclusion: { in: IMPORT_STATUSES }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
  scope :importable, -> { active.where.not(import_status: 'excluded') }
  scope :listed, -> { where(active: true).or(where(skip_analysis: true)) }

  def exclude_from_analysis!
    transaction do
      update!(skip_analysis: true)
      skip_pending_analysis!
    end
  end

  def include_in_analysis!
    update!(skip_analysis: false)
  end

  def skip_pending_analysis!
    LogEntry.where(source_container: name, analysis_status: %w[pending analyzing]).find_each do |entry|
      entry.update!(analysis_status: 'excluded', analysis_error: nil)
    end
  end

  def mark_importing!
    update!(import_status: 'importing', import_error: nil)
  end

  def mark_import_succeeded!(log_cursor_at:)
    update!(
      import_status: 'succeeded',
      import_error: nil,
      last_imported_at: Time.current,
      log_cursor_at: log_cursor_at
    )
  end

  def mark_import_failed!(message)
    update!(import_status: 'failed', import_error: message)
  end
end
