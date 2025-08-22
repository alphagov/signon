require "addressable/uri"

module ApplicationHelper
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    if recognized[:controller] == params[:controller] &&
        recognized[:action] == params[:action]
      tag.li(class: "active") do
        link_to(text, link)
      end
    else
      tag.li do
        link_to(text, link)
      end
    end
  end

  SENSITIVE_QUERY_PARAMETERS = %w[reset_password_token invitation_token].freeze

  def sensitive_query_parameters = SENSITIVE_QUERY_PARAMETERS

  def sensitive_query_parameters?
    (request.query_parameters.keys & SENSITIVE_QUERY_PARAMETERS).any?
  end

  def sanitised_fullpath
    uri = Addressable::URI.parse(request.fullpath)
    uri.query_values = uri.query_values.reject { |key, _value| SENSITIVE_QUERY_PARAMETERS.include?(key) }
    uri.to_s
  end

  def with_checked_options_at_top(options)
    options.sort_by { |o| o[:checked] ? 0 : 1 }
  end

  def govuk_tag(text, classes = nil)
    css_classes = ["govuk-tag", classes].compact.join(" ")
    tag.strong(text, class: css_classes)
  end
end
