# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Inference
  # HTTP client for sending log entries to the configured inference service.
  class Client
    # Base inference client error; permanent failures (wrong URL, auth, etc.).
    class Error < StandardError
      RETRYABLE_STATUS_CODES = [408, 429, 500, 502, 503, 504].freeze

      attr_reader :status_code

      def initialize(message, status_code: nil)
        super(message)
        @status_code = status_code
      end

      def retryable?
        false
      end
    end

    # Transient inference failure that Sidekiq should retry (5xx, rate limits).
    class RetryableError < Error
      def retryable?
        true
      end
    end

    class ConfigurationError < Error
    end

    DEFAULT_MODEL = 'log-analyzer'
    MODEL_UNAVAILABLE_PATTERN = /model/i
    API_FORMATS = %w[loglady openai].freeze

    def initialize(**options)
      @endpoint = env_option(options, :endpoint, 'INFERENCE_URL')
      @api_key = env_option(options, :api_key, 'INFERENCE_API_KEY')
      @model = env_option(options, :model, 'INFERENCE_MODEL', DEFAULT_MODEL)
      @fallback_model = options.fetch(:fallback_model) { ENV['INFERENCE_FALLBACK_MODEL'].presence }
      @timeout = env_option(options, :timeout, 'INFERENCE_TIMEOUT_SECONDS', 30).to_i
      @prompt = options.fetch(:prompt) { Prompt.resolve }
      @api_format = resolve_api_format(options)
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

    attr_reader :endpoint, :api_key, :model, :fallback_model, :timeout, :prompt, :api_format

    def models_for_attempt
      @models_for_attempt ||= [model, fallback_model].compact.uniq
    end

    def env_option(options, key, env_key, default = nil)
      options.fetch(key) { ENV.fetch(env_key, default) }
    end

    def resolve_api_format(options)
      options.fetch(:api_format) { ENV.fetch('INFERENCE_API_FORMAT', 'loglady') }
    end

    def validate_configuration!
      raise ConfigurationError, 'INFERENCE_URL is required' if endpoint.blank?
      raise ConfigurationError, 'INFERENCE_API_KEY is required' if api_key.blank?
      raise ConfigurationError, 'INFERENCE_PROMPT is required' if prompt.blank?
      return if API_FORMATS.include?(api_format)

      raise ConfigurationError, "INFERENCE_API_FORMAT must be one of: #{API_FORMATS.join(', ')}"
    end

    def perform_request(log_entry, model_name)
      http.request(build_request(log_entry, model_name))
    end

    def build_request(log_entry, model_name)
      RequestBuilder.build(
        log_entry: log_entry,
        model_name: model_name,
        prompt: prompt,
        endpoint: endpoint,
        api_format: api_format
      ).tap do |request|
        request['Authorization'] = "Bearer #{api_key}"
      end
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

      status_code = response.code.to_i
      message = "Inference server returned #{response.code}: #{response.body}"
      error_class = Error::RETRYABLE_STATUS_CODES.include?(status_code) ? RetryableError : Error
      raise error_class.new(message, status_code: status_code)
    end

    def parse_body(response)
      ResponseBody.normalize(JSON.parse(response.body), api_format: api_format)
    end

    def http
      uri = URI(endpoint)
      Net::HTTP.new(uri.host, uri.port).tap do |client|
        client.use_ssl = uri.scheme == 'https'
        client.open_timeout = timeout
        client.read_timeout = timeout
      end
    end
  end
end
