# frozen_string_literal: true

module Inference
  # Parses inference API JSON into a structured AnalysisResult.
  class AnalysisParser
    REQUIRED_KEYS = %w[classification urgency needs_action fixes other_suggestions].freeze
    CLASSIFICATIONS = %w[connectivity informational configuration].freeze
    URGENCIES = %w[low medium high critical].freeze

    def self.parse(data)
      new(data).parse
    end

    def initialize(data)
      @data = data
    end

    def parse
      payload = extract_payload
      validate_keys!(payload)
      AnalysisResult.new(
        classification: normalize_classification(payload['classification']),
        urgency: normalize_urgency(payload['urgency']),
        needs_action: normalize_boolean(payload['needs_action']),
        fixes: normalize_string_list(payload['fixes'], key: 'fixes'),
        other_suggestions: normalize_string_list(payload['other_suggestions'], key: 'other_suggestions')
      )
    end

    private

    attr_reader :data

    def extract_payload
      payload = parse_analysis_field(data['analysis'])
      payload = data if payload.nil? && data.key?('classification')
      payload or raise_error('Response is missing structured analysis fields')
    rescue JSON::ParserError => e
      raise Client::Error, "Inference analysis is not valid JSON: #{e.message}"
    end

    def parse_analysis_field(analysis)
      return analysis if analysis.is_a?(Hash)
      return JSON.parse(analysis) if analysis.is_a?(String)

      nil
    end

    def validate_keys!(payload)
      missing = REQUIRED_KEYS - payload.keys
      return if missing.empty?

      raise Client::Error, "Inference analysis is missing keys: #{missing.join(', ')}"
    end

    def normalize_classification(value)
      classification = value.to_s.strip.downcase
      return classification if CLASSIFICATIONS.include?(classification)

      raise Client::Error,
            "Inference classification must be one of: #{CLASSIFICATIONS.join(', ')} (got #{value.inspect})"
    end

    def normalize_urgency(value)
      urgency = value.to_s.strip.downcase
      return urgency if URGENCIES.include?(urgency)

      raise Client::Error, "Inference urgency must be one of: #{URGENCIES.join(', ')} (got #{value.inspect})"
    end

    def normalize_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def normalize_string_list(value, key:)
      coerce_string_list(value, key).map { |item| item.to_s.strip }.compact_blank
    end

    def coerce_string_list(value, key)
      case value
      when Array then value
      when String then value.blank? ? [] : [value]
      when nil then []
      else
        raise Client::Error, "Inference #{key} must be an array of strings"
      end
    end

    def raise_error(message)
      raise Client::Error, message
    end
  end
end
