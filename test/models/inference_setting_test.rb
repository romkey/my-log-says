# frozen_string_literal: true

require 'test_helper'

class InferenceSettingTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert inference_settings(:default).valid?
  end

  test 'current returns the stored row' do
    setting = inference_settings(:default)

    assert_equal setting, InferenceSetting.current
  end

  test 'requires inference prompt' do
    setting = inference_settings(:default)
    setting.inference_prompt = ''

    assert_not setting.valid?
  end
end
