module UsersWithAccessHelper
  def formatted_user_name(user)
    link = link_to(user.name, edit_user_path(user))

    if user.unusable_account?
      content_tag(:del, link)
    else
      link
    end
  end
end
