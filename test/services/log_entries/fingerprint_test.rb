# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class FingerprintTest < ActiveSupport::TestCase
    CORE = 'Retrying failed request'

    test 'normalizes container stream and message' do
      first = Fingerprint.call(source_container: ' web ', stream: 'STDERR', message: ' failure ')
      second = Fingerprint.call(source_container: 'web', stream: 'stderr', message: 'failure')

      assert_equal first, second
    end

    test 'matches messages that differ only by timestamp prefix' do
      first = Fingerprint.call(
        source_container: 'worker', stream: 'stdout',
        message: "2026-06-03T00:08:58.223Z INFO #{CORE}"
      )
      second = Fingerprint.call(source_container: 'worker', stream: 'stdout', message: "[12345] #{CORE}")

      assert_equal first, second
    end
  end
end
