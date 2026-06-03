# frozen_string_literal: true

# Lists, accepts, and manually queues analysis for collected log entries.
class LogEntriesController < ApplicationController
  protect_from_forgery with: :null_session, only: :create

  def index
    prepare_index_filters
    assign_index_counts
    @log_entries = @filters.apply.recent.limit(100)
  end

  def show
    @log_entry = LogEntry.find(params.expect(:id))
    @docker_container = DockerContainer.find_by(name: @log_entry.source_container)
  end

  def create
    result = LogEntries::Ingestor.call(**log_entry_params)

    render json: {
      id: result.log_entry.id,
      duplicate: result.duplicate,
      occurrence_count: result.log_entry.occurrence_count,
      analysis_status: result.log_entry.analysis_status
    }, status: result.duplicate ? :ok : :created
  end

  def analyze
    log_entry = LogEntry.find(params.expect(:id))
    if DockerContainers::AnalysisExclusion.skipped?(log_entry.source_container)
      redirect_to log_entry_path(log_entry), alert: t('.excluded_container')
      return
    end

    AnalyzeLogEntryJob.perform_later(log_entry.id)
    redirect_to log_entry_path(log_entry), notice: t('.queued')
  end

  private

  def prepare_index_filters
    @filters = LogEntries::Filters.from_params(base_scope: visible_log_entries, params: params)
    @total_count = visible_log_entries.count
    @results_count = @filters.apply.count
    @docker_containers = DockerContainer.listed.order(:name)
    @analysis_excluded_count = DockerContainer.where(skip_analysis: true).count
  end

  def assign_index_counts
    @analysis_counts = @filters.analysis_counts
    @container_counts = @filters.container_counts
    @severity_counts = @filters.severity_counts
  end

  def excluded_containers
    @excluded_containers ||= DockerContainer.where(import_status: 'excluded').pluck(:name)
  end

  def visible_log_entries
    @visible_log_entries ||= begin
      scope = LogEntry.all
      scope = scope.where.not(source_container: excluded_containers) if excluded_containers.any?
      scope
    end
  end

  def log_entry_params
    params.expect(log_entry: [:source_container, :stream, :message, { raw_payload: {} }]).to_h.symbolize_keys
  end
end
