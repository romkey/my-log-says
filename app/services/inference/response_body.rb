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

      content = data.dig('choices', 0, 'message', 'content')
      raise Client::Error.new('OpenAI response missing message content', status_code: 200) if content.blank?

      JSON.parse(content)
    end

    private

    attr_reader :data, :api_format

    def openai_format?
      api_format == 'openai'
    end
  end
end
