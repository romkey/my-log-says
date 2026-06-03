# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class FiltersTest < ActiveSupport::TestCase
    test 'stacked filters narrow results' do
      filters = Filters.new(
        base_scope: LogEntry.all,
        analysis: 'analyzed',
        container: 'web',
        severity: 'high'
      )

      results = filters.apply

      assert_equal 1, results.count
      assert_includes results, log_entries(:analyzed_error)
      assert_not_includes results, log_entries(:analyzed_info)
    end

    test 'toggle removes an active facet' do
      filters = Filters.new(base_scope: LogEntry.all, analysis: 'analyzed')
      toggled = filters.toggle(:analysis, 'analyzed')

      assert_nil toggled.analysis
      assert_operator toggled.apply.count, :>, filters.apply.count
    end

    test 'toggle adds an inactive facet' do
      filters = Filters.new(base_scope: LogEntry.all)
      toggled = filters.toggle(:container, 'web')

      assert_equal 'web', toggled.container
      assert_equal 2, toggled.apply.count
    end

    test 'facet counts respect other active filters' do
      filters = Filters.new(base_scope: LogEntry.all, analysis: 'analyzed')

      assert_equal 2, filters.container_counts.find { |name, _| name == 'web' }.last
      assert_equal 1, filters.severity_counts.find { |level, _| level == 'high' }.last
      assert_equal 1, filters.severity_counts.find { |level, _| level == 'low' }.last
    end

    test 'ignores invalid filter values' do
      filters = Filters.from_params(
        base_scope: LogEntry.all,
        params: ActionController::Parameters.new(
          analysis: 'bogus',
          severity: 'extreme',
          container: 'web'
        )
      )

      assert_nil filters.analysis
      assert_nil filters.severity
      assert_equal 'web', filters.container
    end
  end
end
