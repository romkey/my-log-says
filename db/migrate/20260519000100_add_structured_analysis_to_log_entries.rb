# frozen_string_literal: true

class AddStructuredAnalysisToLogEntries < ActiveRecord::Migration[8.1]
  def change
    remove_column :log_entries, :analysis, :text

    add_column :log_entries, :classification, :string
    add_column :log_entries, :urgency, :string
    add_column :log_entries, :needs_action, :boolean
    add_column :log_entries, :fixes, :jsonb, null: false, default: []
    add_column :log_entries, :other_suggestions, :jsonb, null: false, default: []

    add_index :log_entries, :classification
    add_index :log_entries, :needs_action
  end
end
