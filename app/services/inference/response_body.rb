# frozen_string_literal: true

module Inference
  # Normalizes inference API responses into the shape expected by AnalysisParser.
  class ResponseBody
    def self.normalize(data, api_format:)
      new(data, api_format: api_format).normalize
    end

    def initialize(data, api_format:)
      @data = data
      @api_format = api_format.to_s
    end

    def normalize
      return data unless openai_format?

      parse_openai_content
    end

    def parse_openai_content
      content = data.dig('choices', 0, 'message', 'content')
      raise_missing_content if content.blank?

      JSON.parse(content)
    rescue JSON::ParserError => e
      raise_invalid_content(content, e)
    end

    def raise_missing_content
      raise Client::Error.new(
        ErrorContext.append(data, 'OpenAI response missing message content'),
        status_code: 200
      )
    end

    def raise_invalid_content(content, error)
      raise Client::Error.new(
        ErrorContext.append(content, "OpenAI message content is not valid JSON: #{error.message}"),
        status_code: 200
      )
    end

    private

    attr_reader :data, :api_format

    def openai_format?
      api_format == 'openai'
    end
  end
end
