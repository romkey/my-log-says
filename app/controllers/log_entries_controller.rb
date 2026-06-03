# frozen_string_literal: true

# Lists, accepts, and manually queues analysis for collected log entries.
class LogEntriesController < ApplicationController
  protect_from_forgery with: :null_session, only: :create

  def index
    @analysis_filter = analysis_filter_param
    @analysis_counts = visible_log_entries.group(:analysis_status).count
    @analyzed_count = @analysis_counts.fetch('analyzed', 0)
    @failed_count = @analysis_counts.fetch('failed', 0)
    @total_count = @analysis_counts.values.sum
    @log_entries = filtered_log_entries.limit(100)
  end

  def show
    @log_entry = LogEntry.find(params.expect(:id))
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
    AnalyzeLogEntryJob.perform_later(params[:id])
    redirect_to log_entry_path(params[:id]), notice: t('.queued')
  end

  private

  def analysis_filter_param
    status = params.permit(:analysis)[:analysis].to_s.presence
    status if status.in?(LogEntry::STATUSES)
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

  def filtered_log_entries
    scope = visible_log_entries.recent
    scope = scope.with_analysis_status(@analysis_filter) if @analysis_filter
    scope
  end

  def log_entry_params
    params.expect(log_entry: [:source_container, :stream, :message, { raw_payload: {} }]).to_h.symbolize_keys
  end
end
