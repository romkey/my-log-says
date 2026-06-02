# frozen_string_literal: true

require 'test_helper'

class DockerEntrypointTest < ActiveSupport::TestCase
  ENTRYPOINT = Rails.root.join('bin/docker-entrypoint')

  test 'only migrates for the web server command' do
    script = File.read(ENTRYPOINT)

    assert_includes script, './bin/rails db:migrate'
    assert_not_includes script, 'db:prepare'
    assert_not_includes script, 'sidekiq'
  end
end
