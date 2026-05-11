# frozen_string_literal: true

require 'test_helper'

class ImportDockerLogsJobTest < ActiveJob::TestCase
  test 'imports logs for the requested container' do
    test_case = self
    original_call = DockerLogs::Importer.method(:call)
    DockerLogs::Importer.define_singleton_method(:call) { |container_name:| test_case.assert_equal 'web', container_name }

    ImportDockerLogsJob.perform_now('web')
  ensure
    DockerLogs::Importer.define_singleton_method(:call, original_call)
  end
end
