# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class LineGrouperTest < ActiveSupport::TestCase
    HA_WARNING = '2026-06-03 07:01:31.838 WARNING (MainThread) [homeassistant.components.bond.entity] ' \
                 'Entity button.somfy_shade_preset has become unavailable'
    HA_WARNING_TWO = '2026-06-03 07:01:31.840 WARNING (MainThread) [homeassistant.components.bond.entity] ' \
                     'Entity button.shade_preset has become unavailable'

    def entry(message, observed_at: Time.zone.parse('2026-06-03T07:01:31Z'))
      StreamDemuxer::Entry.new(
        stream: 'stderr',
        timestamp: observed_at.iso8601,
        message: message,
        observed_at: observed_at
      )
    end

    test 'folds home assistant warning traceback and timeout into one entry' do
      entries = [
        entry(HA_WARNING),
        entry('Traceback (most recent call last):', observed_at: Time.zone.parse('2026-06-03T07:01:31.001Z')),
        entry('  File "/usr/local/lib/python3.14/site-packages/aiohttp/client.py", line 788, in _request',
              observed_at: Time.zone.parse('2026-06-03T07:01:31.002Z')),
        entry('TimeoutError', observed_at: Time.zone.parse('2026-06-03T07:01:31.003Z'))
      ]

      grouped = LineGrouper.call(entries)

      assert_equal 1, grouped.length
      assert_includes grouped.first.message, HA_WARNING
      assert_includes grouped.first.message, 'Traceback (most recent call last):'
      assert_includes grouped.first.message, 'TimeoutError'
      assert_equal Time.zone.parse('2026-06-03T07:01:31.003Z'), grouped.first.observed_at
    end

    test 'keeps interleaved warnings as separate entries with their tracebacks' do
      entries = [
        entry('2026-06-03 07:01:31.837 WARNING (MainThread) [bond] Updating cover took longer than interval'),
        entry(HA_WARNING),
        entry('Traceback (most recent call last):', observed_at: Time.zone.parse('2026-06-03T07:01:31.001Z')),
        entry('  File "/bond/entity.py", line 142, in _async_update_from_api',
              observed_at: Time.zone.parse('2026-06-03T07:01:31.002Z')),
        entry('TimeoutError', observed_at: Time.zone.parse('2026-06-03T07:01:31.003Z')),
        entry(HA_WARNING_TWO, observed_at: Time.zone.parse('2026-06-03T07:01:31.840Z')),
        entry('Traceback (most recent call last):', observed_at: Time.zone.parse('2026-06-03T07:01:31.841Z')),
        entry('TimeoutError', observed_at: Time.zone.parse('2026-06-03T07:01:31.842Z'))
      ]

      grouped = LineGrouper.call(entries)

      assert_equal 3, grouped.length
      assert_includes grouped[0].message, 'Updating cover took longer'
      assert_not_includes grouped[0].message, 'Traceback'

      assert_includes grouped[1].message, HA_WARNING
      assert_includes grouped[1].message, 'Traceback'
      assert_includes grouped[1].message, 'TimeoutError'

      assert_includes grouped[2].message, HA_WARNING_TWO
      assert_includes grouped[2].message, 'Traceback'
    end

    test 'does not merge non traceback continuation lines' do
      entries = [
        entry('2026-06-03T07:01:31.838Z INFO service started'),
        entry('continued narrative line without traceback shape')
      ]

      grouped = LineGrouper.call(entries)

      assert_equal 2, grouped.length
      assert_equal 'continued narrative line without traceback shape', grouped.last.message
    end

    test 'returns entries unchanged when multiline grouping is disabled' do
      entries = [
        entry(HA_WARNING),
        entry('Traceback (most recent call last):')
      ]

      grouped = with_env('DOCKER_LOG_GROUP_MULTILINE' => 'false') do
        LineGrouper.call(entries)
      end

      assert_equal 2, grouped.length
    end

    private

    def with_env(overrides)
      original = overrides.keys.index_with { |key| ENV.fetch(key, nil) }
      overrides.each { |key, value| ENV[key] = value }
      yield
    ensure
      original.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end
  end
end
