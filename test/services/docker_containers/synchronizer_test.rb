# frozen_string_literal: true

require 'test_helper'

module DockerContainers
  class SynchronizerTest < ActiveSupport::TestCase
    setup do
      @original_skip = ENV.fetch('DOCKER_LOG_SKIP_SELF', nil)
      ENV['DOCKER_LOG_SKIP_SELF'] = 'true'
    end

    teardown do
      if @original_skip.nil?
        ENV.delete('DOCKER_LOG_SKIP_SELF')
      else
        ENV['DOCKER_LOG_SKIP_SELF'] = @original_skip
      end
    end

    test 'upserts discovered containers and deactivates missing ones' do
      client = Object.new
      client.define_singleton_method(:list_containers) do |**|
        [
          {
            'Id' => 'abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123',
            'Names' => ['/api'],
            'Image' => 'api:latest',
            'State' => 'running'
          }
        ]
      end

      assert_difference -> { DockerContainer.count }, 1 do
        result = Synchronizer.call(client: client)

        assert_equal 1, result.containers.length
        assert_equal 1, result.deactivated_count
        assert_equal 0, result.excluded_count
      end

      api = DockerContainer.find_by!(name: 'api')

      assert api.active?
      assert_equal 'running', api.state

      web = docker_containers(:web)

      assert_not web.reload.active?
      assert_equal 'removed', web.state
    end

    test 'marks loglady containers as excluded' do
      client = Object.new
      client.define_singleton_method(:list_containers) do |**|
        [
          {
            'Id' => 'def456def456def456def456def456def456def456def456def456def456',
            'Names' => ['/log-lady-sidekiq-1'],
            'Image' => 'ghcr.io/romkey/loglady:latest',
            'State' => 'running'
          }
        ]
      end

      result = Synchronizer.call(client: client)

      assert_empty result.containers
      assert_equal 1, result.excluded_count

      sidekiq = DockerContainer.find_by!(name: 'log-lady-sidekiq-1')

      assert_not sidekiq.active?
      assert_equal 'excluded', sidekiq.import_status
    end
  end
end
