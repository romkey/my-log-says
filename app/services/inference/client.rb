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
    MODEL_UNAVAILABLE_PATTERN = /model/i

    def initialize(**options)
      @endpoint = options.fetch(:endpoint) { ENV.fetch('INFERENCE_URL', nil) }
      @api_key = options.fetch(:api_key) { ENV.fetch('INFERENCE_API_KEY', nil) }
      @model = options.fetch(:model) { ENV.fetch('INFERENCE_MODEL', DEFAULT_MODEL) }
      @fallback_model = options.fetch(:fallback_model) { ENV['INFERENCE_FALLBACK_MODEL'].presence }
      @timeout = options.fetch(:timeout) { ENV.fetch('INFERENCE_TIMEOUT_SECONDS', 30).to_i }
      @prompt = options.fetch(:prompt) { Prompt.resolve }
    end

    def analyze(log_entry)
      validate_configuration!

      last_response = nil
      models_for_attempt.each do |model_name|
        last_response = perform_request(log_entry, model_name)
        return AnalysisParser.parse(parse_body(last_response)) if last_response.is_a?(Net::HTTPSuccess)

        raise_response_error!(last_response) unless retry_with_fallback?(last_response, model_name)
      end

      raise_response_error!(last_response)
    rescue JSON::ParserError => e
      raise Error, "Inference server returned invalid JSON: #{e.message}"
    end

    private

    attr_reader :endpoint, :api_key, :model, :fallback_model, :timeout, :prompt

    def models_for_attempt
      @models_for_attempt ||= [model, fallback_model].compact.uniq
    end

    def validate_configuration!
      raise ConfigurationError, 'INFERENCE_URL is required' if endpoint.blank?
      raise ConfigurationError, 'INFERENCE_API_KEY is required' if api_key.blank?
      raise ConfigurationError, 'INFERENCE_PROMPT is required' if prompt.blank?
    end

    def perform_request(log_entry, model_name)
      http.request(request_for(log_entry, model_name))
    end

    def retry_with_fallback?(response, model_name)
      fallback_model.present? &&
        model_name != models_for_attempt.last &&
        model_unavailable?(response)
    end

    def model_unavailable?(response)
      code = response.code.to_i
      return true if [404, 410].include?(code)
      return true if [400, 422, 503].include?(code) && response.body.match?(MODEL_UNAVAILABLE_PATTERN)

      false
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

    def request_for(log_entry, model_name)
      uri = URI(endpoint)
      Net::HTTP::Post.new(uri.request_uri).tap do |request|
        request['Authorization'] = "Bearer #{api_key}"
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(payload_for(log_entry, model_name))
      end
    end

    def payload_for(log_entry, model_name)
      {
        model: model_name,
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
