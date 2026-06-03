# frozen_string_literal: true

# View helpers for LogLady pages.
module ApplicationHelper
  SEVERITY_CHIP_VARIANTS = {
    'critical' => 'danger',
    'high' => 'danger',
    'medium' => 'warning'
  }.freeze

  def log_entry_filter_chip(filters:, facet:, value:, **options)
    label = options.fetch(:label)
    count = options.fetch(:count)
    active = filters.public_send(facet) == value

    path = log_entries_path(filters.toggle(facet, value).to_params)
    chip_classes = filter_chip_classes(active:, value:, variant: options[:variant])

    link_to path, class: chip_classes do
      safe_join([label, content_tag(:span, count, class: count.positive? ? 'text-body fw-medium' : 'text-secondary')])
    end
  end

  def container_analysis_toggle(container, filters:)
    path = toggle_analysis_docker_container_path(container, filters.to_params)
    classes = ['filter-chip']
    classes << 'muted' if container.skip_analysis?
    subtitle = container.skip_analysis? ? 'No analysis' : 'Analyzing'
    subtitle_class = container.skip_analysis? ? 'text-secondary' : 'text-body'

    button_to path, method: :patch, form: { class: 'd-inline filter-chip-form' }, class: classes.join(' '),
                    title: container.skip_analysis? ? 'Include in analysis' : 'Exclude from analysis' do
      safe_join([container.name, content_tag(:span, subtitle, class: subtitle_class)])
    end
  end

  def log_entry_container_stream_path(log_entry)
    log_entries_path(
      container: log_entry.source_container,
      focus: log_entry.id,
      anchor: "log-entry-#{log_entry.id}"
    )
  end

  def log_entry_severity_label(entry)
    return content_tag(:span, '—', class: 'text-secondary') if entry.urgency.blank?

    if entry.urgency.in?(%w[critical high])
      content_tag(:span, entry.urgency.humanize, class: 'badge text-bg-danger-subtle')
    elsif entry.urgency == 'medium'
      content_tag(:span, entry.urgency.humanize, class: 'text-body')
    else
      content_tag(:span, entry.urgency.humanize, class: 'text-secondary')
    end
  end

  private

  def filter_chip_classes(active:, value:, variant:)
    classes = ['filter-chip']
    classes << 'active' if active
    chip_variant = variant || SEVERITY_CHIP_VARIANTS[value.to_s]
    classes << chip_variant if chip_variant.present? && active
    classes.join(' ')
  end
end
