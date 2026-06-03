# frozen_string_literal: true

# Adds normalized_message for prefix-aware log deduplication.
class AddNormalizedMessageToLogEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :log_entries, :normalized_message, :text
    add_index :log_entries, :normalized_message
  end
end
