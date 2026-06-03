# frozen_string_literal: true

require 'test_helper'

module LogEntries
  class MessageNormalizerTest < ActiveSupport::TestCase
    CORE = 'Retrying failed request'

    test 'strips ISO timestamp and log level' do
      normalized = MessageNormalizer.call("2026-06-03T00:08:58.223Z INFO #{CORE}")

      assert_equal CORE, normalized
    end

    test 'strips bracketed timestamp' do
      normalized = MessageNormalizer.call("[2026-06-03 00:08:58] #{CORE}")

      assert_equal CORE, normalized
    end

    test 'strips bracketed pid' do
      normalized = MessageNormalizer.call("[12345] #{CORE}")

      assert_equal CORE, normalized
    end

    test 'strips sidekiq metadata prefix' do
      normalized = MessageNormalizer.call("pid=1 tid=1ehz9 jid=abc123 #{CORE}")

      assert_equal CORE, normalized
    end

    test 'strips combined prefixes iteratively' do
      normalized = MessageNormalizer.call("INFO  2026-06-03T00:08:58.223Z pid=1 tid=1ehz9 #{CORE}")

      assert_equal CORE, normalized
    end

    test 'does not strip meaningful leading digits' do
      message = '404 Not Found from upstream'

      assert_equal message, MessageNormalizer.call(message)
    end

    test 'falls back to original message when normalization is empty' do
      assert_equal 'INFO', MessageNormalizer.call('INFO')
    end
  end
end
