# frozen_string_literal: true

require 'test_helper'

class DockerContainersControllerTest < ActionDispatch::IntegrationTest
  test 'excludes a container from analysis' do
    container = docker_containers(:web)

    patch toggle_analysis_docker_container_url(container)

    assert_redirected_to log_entries_url
    assert container.reload.skip_analysis?
    follow_redirect!
    assert_includes response.body, 'web excluded from analysis'
  end

  test 'includes a container back in analysis' do
    container = docker_containers(:web)
    container.exclude_from_analysis!

    patch toggle_analysis_docker_container_url(container)

    assert_not container.reload.skip_analysis?
    follow_redirect!
    assert_includes response.body, 'web will be analyzed again'
  end

  test 'excludes a container by name when no docker record exists yet' do
    patch toggle_container_analysis_by_name_url(name: 'legacy-worker')

    assert DockerContainer.exists?(name: 'legacy-worker', skip_analysis: true)
  end
end
