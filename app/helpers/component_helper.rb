module ComponentHelper
  def navigation_items
    return [] unless current_user

    items = []

    unless content_for(:suppress_navbar_items)
      items << { text: "Dashboard", href: root_path, active: is_current?(root_path) }

      if policy(User).index?
        items << { text: "Users", href: users_path, active: is_current?(users_path) }
      end

      if policy(ApiUser).index?
        items << { text: "APIs", href: api_users_path, active: is_current?(api_users_path) }
      end

      if policy(Doorkeeper::Application).index?
        items << { text: "Apps", href: doorkeeper_applications_path, active: is_current?(doorkeeper_applications_path) }
      end

      if policy(Organisation).index?
        items << { text: "Orgs", href: organisations_path, active: is_current?(organisations_path) }
      end
    end

    items << { text: current_user.name, href: user_link_target }
    items << { text: "Sign out", href: destroy_user_session_path }

    items
  end

  def is_current?(link)
    recognized = Rails.application.routes.recognize_path(link)
    recognized[:controller] == params[:controller] &&
      recognized[:action] == params[:action]
  end
end
