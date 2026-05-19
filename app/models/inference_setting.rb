# frozen_string_literal: true

# Singleton inference configuration editable from the running app.
class InferenceSetting < ApplicationRecord
  validates :inference_prompt, presence: true

  def self.current
    first || create!(inference_prompt: Inference::Prompt.default_content)
  end
end
