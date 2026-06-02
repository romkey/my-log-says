# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class SinceParserTest < ActiveSupport::TestCase
    test 'parses minute offsets' do
      travel_to Time.zone.parse('2026-06-02T12:00:00Z') do
        assert_equal Time.zone.parse('2026-06-02T11:50:00Z'), SinceParser.call('10m')
      end
    end

    test 'parses hour offsets' do
      travel_to Time.zone.parse('2026-06-02T12:00:00Z') do
        assert_equal Time.zone.parse('2026-06-02T10:00:00Z'), SinceParser.call('2h')
      end
    end

    test 'defaults unknown values to ten minutes' do
      travel_to Time.zone.parse('2026-06-02T12:00:00Z') do
        assert_equal Time.zone.parse('2026-06-02T11:50:00Z'), SinceParser.call('nope')
      end
    end
  end
end
