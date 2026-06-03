# frozen_string_literal: true

require 'test_helper'

module Inference
  class AnalysisParserTest < ActiveSupport::TestCase
    VALID_PAYLOAD = {
      'classification' => 'informational',
      'urgency' => 'low',
      'needs_action' => false,
      'fixes' => [],
      'other_suggestions' => ['Monitor volume over the next hour.']
    }.freeze

    test 'parses top-level structured response' do
      result = AnalysisParser.parse(VALID_PAYLOAD)

      assert_equal 'informational', result.classification
      assert_equal 'low', result.urgency
      assert_not result.needs_action
      assert_empty result.fixes
      assert_equal ['Monitor volume over the next hour.'], result.other_suggestions
    end

    test 'parses nested analysis object' do
      result = AnalysisParser.parse('analysis' => VALID_PAYLOAD)

      assert_equal 'informational', result.classification
    end

    test 'parses analysis json string' do
      result = AnalysisParser.parse('analysis' => VALID_PAYLOAD.to_json)

      assert_equal 'informational', result.classification
    end

    test 'rejects invalid classification' do
      payload = VALID_PAYLOAD.merge('classification' => 'security')

      error = assert_raises Client::Error do
        AnalysisParser.parse(payload)
      end

      assert_match(/classification/, error.message)
      assert_match(/security/, error.message)
      assert_match(/Response:/, error.message)
    end

    test 'rejects missing keys' do
      payload = { 'classification' => 'informational' }

      error = assert_raises Client::Error do
        AnalysisParser.parse(payload)
      end

      assert_match(/missing keys/, error.message)
      assert_match(/Response:.*informational/, error.message)
    end

    test 'rejects invalid analysis json string' do
      error = assert_raises Client::Error do
        AnalysisParser.parse('analysis' => 'not-json')
      end

      assert_match(/not valid JSON/, error.message)
      assert_match(/Response: not-json/, error.message)
    end

    test 'rejects response missing structured fields' do
      error = assert_raises Client::Error do
        AnalysisParser.parse('status' => 'ok')
      end

      assert_match(/missing structured analysis fields/, error.message)
      assert_match(/Response:.*ok/, error.message)
    end
  end
end
