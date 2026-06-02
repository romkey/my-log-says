# frozen_string_literal: true

require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test 'shows settings form' do
    get settings_url

    assert_response :success
    assert_includes response.body, 'LLM prompt'
    assert_includes response.body, inference_settings(:default).inference_prompt
  end

  test 'updates inference prompt' do
    patch settings_url, params: {
      inference_setting: { inference_prompt: 'Updated prompt with classification key.' }
    }

    assert_redirected_to settings_url
    assert_equal 'Updated prompt with classification key.', inference_settings(:default).reload.inference_prompt
  end

  test 'rejects blank prompt' do
    patch settings_url, params: { inference_setting: { inference_prompt: '' } }

    assert_response :unprocessable_content
    assert_includes response.body, 'cannot be blank'
  end

  test 'restores example prompt' do
    post restore_default_settings_url

    assert_redirected_to settings_url
    assert_includes inference_settings(:default).reload.inference_prompt, 'classification'
  end
end
