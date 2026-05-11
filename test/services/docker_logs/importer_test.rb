# frozen_string_literal: true

require 'test_helper'

module DockerLogs
  class ImporterTest < ActiveJob::TestCase
    FakeStatus = Data.define(:successful) do
      def success?
        successful
      end
    end

    test 'imports docker log lines' do
      runner = lambda do |*command|
        assert_equal ['docker', 'logs', '--timestamps', '--since=5m', 'web'], command
        ["2026-05-11T03:30:00Z database timeout\n", '', FakeStatus.new(true)]
      end

      assert_difference -> { LogEntry.count }, 1 do
        result = Importer.call(container_name: 'web', since: '5m', command_runner: runner)

        assert_equal 1, result.imported_count
        assert_equal 0, result.duplicate_count
      end
    end

    test 'reports duplicate imported lines' do
      message = "2026-05-11T03:30:00Z database timeout\n"
      runner = ->(*) { [message + message, '', FakeStatus.new(true)] }

      result = Importer.call(container_name: 'web', since: '5m', command_runner: runner)

      assert_equal 2, result.imported_count
      assert_equal 1, result.duplicate_count
    end

    test 'raises when docker logs fails' do
      runner = ->(*) { ['', 'container not found', FakeStatus.new(false)] }

      error = assert_raises Importer::Error do
        Importer.call(container_name: 'missing', command_runner: runner)
      end

      assert_equal 'container not found', error.message
    end
  end
end
