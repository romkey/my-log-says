# frozen_string_literal: true

require 'test_helper'

class SyncDockerContainersJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  test 'syncs containers and enqueues import jobs' do
    web = docker_containers(:web)
    original_call = DockerContainers::Synchronizer.method(:call)
    DockerContainers::Synchronizer.define_singleton_method(:call) do
      DockerContainers::Synchronizer::Result.new(
        containers: DockerContainer.where(id: web.id),
        deactivated_count: 0
      )
    end

    assert_enqueued_with(job: ImportDockerLogsJob, args: [web.id]) do
      SyncDockerContainersJob.perform_now
    end
  ensure
    DockerContainers::Synchronizer.define_singleton_method(:call, original_call)
  end
end
