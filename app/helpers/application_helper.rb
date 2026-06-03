# frozen_string_literal: true

# View helpers for LogLady pages.
module ApplicationHelper
  def log_entry_filter_chip(label:, count:, filter:, active_filter:, variant: nil)
    classes = ['filter-chip']
    classes << 'active' if active_filter == filter
    classes << variant if variant.present? && active_filter == filter

    link_to log_entries_path(analysis: filter), class: classes.join(' ') do
      safe_join([label, content_tag(:span, count, class: count.positive? ? 'text-body fw-medium' : 'text-secondary')])
    end
  end
end
