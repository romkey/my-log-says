# frozen_string_literal: true

# Adds per-container opt-out for LLM analysis.
class AddSkipAnalysisToDockerContainers < ActiveRecord::Migration[8.1]
  def change
    add_column :docker_containers, :skip_analysis, :boolean, default: false, null: false
    add_index :docker_containers, :skip_analysis
  end
end
