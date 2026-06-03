# frozen_string_literal: true

module LogEntries
  # Parses and applies stacked index filters for log entries.
  class Filters
    ANALYSIS_FACETS = %w[analyzed failed].freeze
    SEVERITY_ORDER = LogEntry::URGENCIES.reverse.freeze

    attr_reader :base_scope, :analysis, :container, :severity

    def self.from_params(base_scope:, params:)
      permitted = params.permit(:analysis, :container, :severity)
      new(
        base_scope: base_scope,
        analysis: permitted[:analysis].to_s.presence,
        container: permitted[:container].presence,
        severity: permitted[:severity].to_s.presence
      )
    end

    def initialize(base_scope:, analysis: nil, container: nil, severity: nil)
      @base_scope = base_scope
      @analysis = analysis if analysis.in?(LogEntry::STATUSES)
      @container = container.presence
      @severity = severity if severity.in?(LogEntry::URGENCIES)
    end

    def to_params
      { analysis: analysis, container: container, severity: severity }.compact
    end

    def active?
      to_params.any?
    end

    def active_count
      to_params.size
    end

    def apply(scope = base_scope)
      scope = scope.with_analysis_status(analysis) if analysis
      scope = scope.with_container(container) if container
      scope = scope.with_severity(severity) if severity
      scope
    end

    def toggle(facet, value)
      attrs = { analysis: analysis, container: container, severity: severity }
      attrs[facet] = attrs[facet] == value ? nil : value
      self.class.new(base_scope: base_scope, **attrs)
    end

    def analysis_counts
      without_facet(:analysis).apply.group(:analysis_status).count
    end

    def container_counts
      without_facet(:container).apply.group(:source_container).count.sort_by { |name, count| [-count, name] }
    end

    def severity_counts
      counts = without_facet(:severity).apply.where.not(urgency: nil).group(:urgency).count
      SEVERITY_ORDER.filter_map { |level| [level, counts[level]] if counts[level].to_i.positive? }
    end

    private

    def without_facet(facet)
      attrs = { analysis: analysis, container: container, severity: severity }
      attrs[facet] = nil
      self.class.new(base_scope: base_scope, **attrs)
    end
  end
end
