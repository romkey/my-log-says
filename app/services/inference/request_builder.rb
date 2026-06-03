# frozen_string_literal: true

module Inference
  # Builds HTTP requests for supported inference API formats.
  class RequestBuilder
    def self.build(log_entry:, model_name:, prompt:, endpoint:, api_format:)
      new(
        log_entry: log_entry,
        model_name: model_name,
        prompt: prompt,
        endpoint: endpoint,
        api_format: api_format
      ).build
    end

    def initialize(log_entry:, model_name:, prompt:, endpoint:, api_format:)
      @log_entry = log_entry
      @model_name = model_name
      @prompt = prompt
      @endpoint = endpoint
      @api_format = api_format.to_s
    end

    def build
      uri = URI(endpoint)
      request = Net::HTTP::Post.new(request_path(uri))
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(payload)
      request
    end

    private

    attr_reader :log_entry, :model_name, :prompt, :endpoint, :api_format

    def request_path(uri)
      return uri.request_uri unless openai_format?

      path = uri.path.to_s.chomp('/')
      path = "#{path}/chat/completions" unless path.end_with?('chat/completions')
      uri.query ? "#{path}?#{uri.query}" : path
    end

    def payload
      return openai_payload if openai_format?

      {
        model: model_name,
        prompt: prompt,
        log_entry: log_entry_payload
      }
    end

    def openai_payload
      {
        model: model_name,
        messages: [
          { role: 'system', content: prompt },
          { role: 'user', content: JSON.generate(log_entry_payload) }
        ],
        response_format: { type: 'json_object' }
      }
    end

    def log_entry_payload
      {
        id: log_entry.id,
        source_container: log_entry.source_container,
        stream: log_entry.stream,
        message: log_entry.message,
        occurrence_count: log_entry.occurrence_count,
        first_seen_at: log_entry.first_seen_at&.iso8601,
        last_seen_at: log_entry.last_seen_at&.iso8601
      }
    end

    def openai_format?
      api_format == 'openai'
    end
  end
end
