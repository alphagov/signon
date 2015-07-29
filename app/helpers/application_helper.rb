module ApplicationHelper
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    if recognized[:controller] == params[:controller] &&
        recognized[:action] == params[:action]
      content_tag(:li, class: "active") do
        link_to(text, link)
      end
    else
      content_tag(:li) do
        link_to(text, link)
      end
    end
  end

  def user_link_target
    # The page the current user's name in the header should link them to
    if policy(current_user).edit?
      edit_user_path(current_user)
    else
      edit_email_or_passphrase_user_path(current_user)
    end
  end
end
