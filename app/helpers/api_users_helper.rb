module ApiUsersHelper
  def truncate_access_token(token)
    raw "#{token[0..7]}#{'&bull;' * 24}#{token[-8..]}"
  end

  def api_user_name(user)
    anchor_tag = link_to(user.name, edit_api_user_path(user), class: "govuk-link")
    user.suspended? ? content_tag(:del, anchor_tag) : anchor_tag
  end

  def permissions_by_application(user)
    content_tag(:ul, class: "govuk-list") do
      safe_join(
        visible_applications(user).map do |application|
          next unless user.permissions_for(application).any?

          content_tag(:li) do
            content_tag(:abbr, application.name, title: "Permissions: #{user.permissions_for(application).to_sentence}")
          end
        end,
      )
    end
  end
end
