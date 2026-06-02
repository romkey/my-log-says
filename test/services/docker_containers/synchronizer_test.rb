# frozen_string_literal: true

require 'test_helper'

module DockerContainers
  class SynchronizerTest < ActiveSupport::TestCase
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
      end

      api = DockerContainer.find_by!(name: 'api')

      assert api.active?
      assert_equal 'running', api.state

      web = docker_containers(:web)

      assert_not web.reload.active?
      assert_equal 'removed', web.state
    end
  end
end
