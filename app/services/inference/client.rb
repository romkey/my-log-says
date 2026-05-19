# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Inference
  # HTTP client for sending log entries to the configured inference service.
  class Client
    class Error < StandardError
    end

    class ConfigurationError < Error
    end

    DEFAULT_MODEL = 'log-analyzer'

    def initialize(
      endpoint: ENV.fetch('INFERENCE_URL', nil),
      api_key: ENV.fetch('INFERENCE_API_KEY', nil),
      model: ENV.fetch('INFERENCE_MODEL', DEFAULT_MODEL),
      timeout: ENV.fetch('INFERENCE_TIMEOUT_SECONDS', 30).to_i,
      prompt: Prompt.resolve
    )
      @endpoint = endpoint
      @api_key = api_key
      @model = model
      @timeout = timeout
      @prompt = prompt
    end

    def analyze(log_entry)
      validate_configuration!

      response = http.request(request_for(log_entry))
      raise_response_error!(response)

      AnalysisParser.parse(parse_body(response))
    rescue JSON::ParserError => e
      raise Error, "Inference server returned invalid JSON: #{e.message}"
    end

    private

    attr_reader :endpoint, :api_key, :model, :timeout, :prompt

    def validate_configuration!
      raise ConfigurationError, 'INFERENCE_URL is required' if endpoint.blank?
      raise ConfigurationError, 'INFERENCE_API_KEY is required' if api_key.blank?
      raise ConfigurationError, 'INFERENCE_PROMPT is required' if prompt.blank?
    end

    def raise_response_error!(response)
      return if response.is_a?(Net::HTTPSuccess)

      raise Error, "Inference server returned #{response.code}: #{response.body}"
    end

    def parse_body(response)
      JSON.parse(response.body)
    end

    def http
      uri = URI(endpoint)
      Net::HTTP.new(uri.host, uri.port).tap do |client|
        client.use_ssl = uri.scheme == 'https'
        client.open_timeout = timeout
        client.read_timeout = timeout
      end
    end

    def request_for(log_entry)
      uri = URI(endpoint)
      Net::HTTP::Post.new(uri.request_uri).tap do |request|
        request['Authorization'] = "Bearer #{api_key}"
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(payload_for(log_entry))
      end
    end

    def payload_for(log_entry)
      {
        model: model,
        prompt: prompt,
        log_entry: log_entry_payload(log_entry)
      }
    end

    def log_entry_payload(log_entry)
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
  end
end
