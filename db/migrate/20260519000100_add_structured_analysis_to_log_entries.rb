# frozen_string_literal: true

# Adds structured LLM analysis columns and removes legacy free-text analysis.
class AddStructuredAnalysisToLogEntries < ActiveRecord::Migration[8.1]
  def change
    change_table :log_entries, bulk: true do |t|
      t.remove :analysis, type: :text
      t.string :classification
      t.string :urgency
      t.boolean :needs_action, default: false, null: false
      t.jsonb :fixes, null: false, default: []
      t.jsonb :other_suggestions, null: false, default: []
    end

    add_index :log_entries, :classification
    add_index :log_entries, :needs_action
  end
end
