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

  def user_link_target
    # The page the current user's name in the header should link them to
    if policy(current_user).edit?
      edit_user_path(current_user)
    else
      edit_email_or_password_user_path(current_user)
    end
  end

  SENSITIVE_QUERY_PARAMETERS = %w[reset_password_token invitation_token].freeze

  def sensitive_query_parameters?
    (request.query_parameters.keys & SENSITIVE_QUERY_PARAMETERS).any?
  end

  def sanitised_fullpath
    uri = Addressable::URI.parse(request.fullpath)
    uri.query_values = uri.query_values.reject { |key, _value| SENSITIVE_QUERY_PARAMETERS.include?(key) }
    uri.to_s
  end
end
