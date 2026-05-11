# frozen_string_literal: true

# Creates the log entries table used for deduplicated Docker logs.
class CreateLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_log_entries_table
    add_log_entry_indexes
  end

  private

  def create_log_entries_table
    create_table :log_entries do |t|
      add_log_entry_columns(t)
      add_analysis_columns(t)
      t.timestamps
    end
  end

  def add_log_entry_columns(table)
    table.string :source_container, null: false
    table.string :stream, null: false, default: 'stdout'
    table.text :message, null: false
    table.string :fingerprint, null: false
    table.integer :occurrence_count, null: false, default: 1
    table.datetime :first_seen_at, null: false
    table.datetime :last_seen_at, null: false
  end

  def add_analysis_columns(table)
    table.string :analysis_status, null: false, default: 'pending'
    table.text :analysis
    table.text :analysis_error
    table.datetime :analyzed_at
    table.jsonb :raw_payload, null: false, default: {}
  end

  def add_log_entry_indexes
    add_index :log_entries, :fingerprint, unique: true
    add_index :log_entries, :last_seen_at
    add_index :log_entries, :analysis_status
  end
end
