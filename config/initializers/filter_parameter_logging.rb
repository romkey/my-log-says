# frozen_string_literal: true

Rails.application.config.filter_parameters += %i[
  api_key
  authorization
  password
  secret
  token
]
