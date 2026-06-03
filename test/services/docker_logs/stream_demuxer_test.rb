# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class StreamDemuxerTest < ActiveSupport::TestCase
    test 'demultiplexes docker log frames' do
      payload = "2026-05-11T03:30:00Z database timeout\n"
      data = [1, 0, 0, 0, payload.bytesize].pack('C4N') + payload

      entries = StreamDemuxer.call(data)

      assert_equal 1, entries.length
      assert_equal 'stdout', entries.first.stream
      assert_equal 'database timeout', entries.first.message
    end

    test 'parses raw log output' do
      data = "2026-05-11T03:30:00Z database timeout\n"

      entries = StreamDemuxer.call(data)

      assert_equal 1, entries.length
      assert_equal 'stdout', entries.first.stream
    end

    test 'peels docker timestamp with nanoseconds from application body' do
      ha_line = '2026-06-03 07:01:31.838 WARNING (MainThread) [bond.entity] Entity unavailable'
      data = "2026-06-03T07:01:31.838000000Z #{ha_line}\n"

      entries = StreamDemuxer.call(data)

      assert_equal 1, entries.length
      assert_equal '2026-06-03T07:01:31.838000000Z', entries.first.timestamp
      assert_equal ha_line, entries.first.message
    end
  end
end
