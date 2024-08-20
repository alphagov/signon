module UsersWithAccessHelper
  def formatted_user_name(user)
    status = if user.invited_but_not_yet_accepted?
               " (invited)"
             elsif user.suspended?
               " (suspended)"
             elsif user.access_locked?
               " (access locked)"
             else
               ""
             end

    "#{link_to(user.name, edit_user_path(user), class: 'govuk-link')}#{status}".html_safe
  end

  def user_name_format(user)
    if user.unusable_account?
      "line-through"
    end
  end

  def formatted_last_sign_in(user)
    if user.current_sign_in_at
      "#{time_ago_in_words(user.current_sign_in_at)} ago"
    else
      "never signed in"
    end
  end
end
