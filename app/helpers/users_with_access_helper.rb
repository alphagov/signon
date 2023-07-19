module UsersWithAccessHelper
  def formatted_user_name(user)
    link = link_to(user.name, edit_user_path(user))

    if user.unusable_account?
      content_tag(:del, link)
    else
      link
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
