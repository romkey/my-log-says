# frozen_string_literal: true

# Tracks a Docker container discovered via the Docker Engine API for log import.
class DockerContainer < ApplicationRecord
  IMPORT_STATUSES = %w[idle importing succeeded failed].freeze

  validates :docker_id, :name, presence: true
  validates :docker_id, uniqueness: true
  validates :import_status, inclusion: { in: IMPORT_STATUSES }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
  scope :importable, -> { active.where.not(state: nil) }

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
