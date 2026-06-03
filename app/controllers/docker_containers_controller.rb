# frozen_string_literal: true

# Toggles whether log entries from a container are sent for LLM analysis.
class DockerContainersController < ApplicationController
  def toggle_analysis
    container = DockerContainer.find(params.expect(:id))
    container.skip_analysis? ? container.include_in_analysis! : container.exclude_from_analysis!
    redirect_back_or_to log_entries_path(filter_params), notice: notice_for(container)
  end

  def toggle_analysis_by_name
    container = DockerContainers::AnalysisExclusion.flip(container_name: params.expect(:name))
    redirect_back_or_to log_entries_path(filter_params), notice: notice_for(container)
  end

  private

  def filter_params
    params.permit(:analysis, :container, :severity).to_h.compact_blank
  end

  def notice_for(container)
    key = container.skip_analysis? ? 'excluded' : 'included'
    t("docker_containers.toggle_analysis.#{key}", name: container.name)
  end
end
