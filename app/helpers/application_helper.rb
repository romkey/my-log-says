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
