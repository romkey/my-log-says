# frozen_string_literal: true

require 'test_helper'

module DockerContainers
  class ImportSkipperTest < ActiveSupport::TestCase
    setup do
      @original_skip = ENV.fetch('DOCKER_LOG_SKIP_SELF', nil)
      @original_project = ENV.fetch('LOGLADY_COMPOSE_PROJECT', nil)
      ENV['DOCKER_LOG_SKIP_SELF'] = 'true'
      ENV.delete('LOGLADY_COMPOSE_PROJECT')
    end

    teardown do
      if @original_skip.nil?
        ENV.delete('DOCKER_LOG_SKIP_SELF')
      else
        ENV['DOCKER_LOG_SKIP_SELF'] = @original_skip
      end

      if @original_project.nil?
        ENV.delete('LOGLADY_COMPOSE_PROJECT')
      else
        ENV['LOGLADY_COMPOSE_PROJECT'] = @original_project
      end
    end

    test 'skips loglady images and names' do
      assert ImportSkipper.skip?('Names' => ['/log-lady-sidekiq-1'], 'Image' => 'ghcr.io/romkey/loglady:latest')
      assert_not ImportSkipper.skip?('Names' => ['/api'], 'Image' => 'api:latest')
    end

    test 'skips containers in the configured compose project' do
      ENV['LOGLADY_COMPOSE_PROJECT'] = 'loglady-server'

      assert ImportSkipper.skip?(
        'Names' => ['/redis'],
        'Image' => 'redis:8',
        'Labels' => { 'com.docker.compose.project' => 'loglady-server' }
      )
      assert_not ImportSkipper.skip?(
        'Names' => ['/api'],
        'Image' => 'api:latest',
        'Labels' => { 'com.docker.compose.project' => 'other-stack' }
      )
    end

    test 'skips containers with the skip label' do
      assert ImportSkipper.skip?(
        'Names' => ['/worker'],
        'Image' => 'worker:latest',
        'Labels' => { 'loglady.io/skip-log-import' => 'true' }
      )
    end
  end
end
