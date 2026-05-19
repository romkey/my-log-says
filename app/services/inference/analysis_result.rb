# frozen_string_literal: true

module Inference
  # Normalized structured analysis returned by the inference service.
  AnalysisResult = Data.define(:classification, :urgency, :needs_action, :fixes, :other_suggestions) do
    def to_log_entry_attributes
      {
        classification: classification,
        urgency: urgency,
        needs_action: needs_action,
        fixes: fixes,
        other_suggestions: other_suggestions
      }
    end
  end
end
