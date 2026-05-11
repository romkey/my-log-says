# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class FingerprintTest < ActiveSupport::TestCase
    test 'normalizes container stream and message' do
      first = Fingerprint.call(source_container: ' web ', stream: 'STDERR', message: ' failure ')
      second = Fingerprint.call(source_container: 'web', stream: 'stderr', message: 'failure')

      assert_equal first, second
    end
  end
end
