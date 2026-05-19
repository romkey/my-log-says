# frozen_string_literal: true

module Inference
  # Resolves the LLM instructions from INFERENCE_PROMPT or the shipped example file.
  class Prompt
    EXAMPLE_PATH = Rails.root.join('config/inference_prompt.example.txt')

    def self.resolve
      explicit = ENV['INFERENCE_PROMPT'].presence
      return explicit if explicit

      file_path = ENV.fetch('INFERENCE_PROMPT_FILE', EXAMPLE_PATH.to_s)
      raise Client::ConfigurationError, "INFERENCE_PROMPT_FILE not found: #{file_path}" unless File.file?(file_path)

      File.read(file_path)
    end
  end
end
