# frozen_string_literal: true

require 'test_helper'

module DockerContainers
  class AnalysisExclusionTest < ActiveSupport::TestCase
    test 'flip excludes and includes analysis for a container name' do
      container = AnalysisExclusion.flip(container_name: 'noisy-sidecar')

      assert container.skip_analysis?
      assert_equal 'noisy-sidecar', container.name

      AnalysisExclusion.flip(container_name: 'noisy-sidecar')

      assert_not container.reload.skip_analysis?
    end

    test 'skipped reflects container setting' do
      docker_containers(:web).exclude_from_analysis!

      assert AnalysisExclusion.skipped?('web')
      assert_not AnalysisExclusion.skipped?('worker')
    end
  end
end
