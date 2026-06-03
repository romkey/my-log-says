# frozen_string_literal: true

module Inference
  # Formats inference payloads for inclusion in error messages.
  module ErrorContext
    MAX_LENGTH = 4_000

    module_function

    def append(source, message)
      return message if source.nil?

      formatted = format(source)
      return message if formatted.blank?

      "#{message}. Response: #{formatted}"
    end

    def format(source)
      text = case source
             when String then source
             when Hash, Array then JSON.generate(source)
             else source.inspect
             end
      truncate(text)
    end

    def truncate(text)
      return text if text.length <= MAX_LENGTH

      "#{text[0, MAX_LENGTH]}… (#{text.length} bytes total)"
    end
  end
end
