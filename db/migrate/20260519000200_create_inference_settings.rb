# frozen_string_literal: true

# Stores runtime-configurable inference settings (singleton row).
class CreateInferenceSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :inference_settings do |t|
      t.text :inference_prompt, null: false
      t.timestamps
    end
  end
end
