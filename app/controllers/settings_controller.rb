# frozen_string_literal: true

# Edits runtime inference configuration.
class SettingsController < ApplicationController
  def show
    @setting = InferenceSetting.current
  end

  def update
    @setting = InferenceSetting.current
    if @setting.update(setting_params)
      redirect_to settings_path, notice: t('.updated')
    else
      flash.now[:alert] = t('.invalid')
      render :show, status: :unprocessable_content
    end
  end

  def restore_default
    InferenceSetting.current.update!(inference_prompt: Inference::Prompt.default_content)
    redirect_to settings_path, notice: t('.restored')
  end

  private

  def setting_params
    params.expect(inference_setting: [:inference_prompt])
  end
end
