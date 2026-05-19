# frozen_string_literal: true

module Inference
  # Resolves the LLM instructions from env, the database, or the example file.
  class Prompt
    EXAMPLE_PATH = Rails.root.join('config/inference_prompt.example.txt')

    def self.resolve
      from_env || from_database || from_file
    end

    def self.default_content
      from_file
    end

    def self.from_env
      ENV['INFERENCE_PROMPT'].presence
    end

    def self.from_database
      InferenceSetting.current.inference_prompt.presence
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      nil
    end

    def self.from_file
      path = ENV.fetch('INFERENCE_PROMPT_FILE', EXAMPLE_PATH.to_s)
      raise Client::ConfigurationError, "INFERENCE_PROMPT_FILE not found: #{path}" unless File.file?(path)

      File.read(path)
    end
  end
end
