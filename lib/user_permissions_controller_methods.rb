module UserPermissionsControllerMethods
  private
    def visible_applications(user)
      if user.api_user?
        authorised_application_ids = user.authorisations.where(revoked_at: nil).pluck(:application_id)
        applications = ::Doorkeeper::Application.where(id: authorised_application_ids)
      elsif current_user.superadmin? || current_user.admin?
        applications = ::Doorkeeper::Application
      else
        applications = ::Doorkeeper::Application.can_signin(current_user).with_signin_delegatable
      end
    end

    def applications_and_permissions(user)
      zip_permissions(visible_applications(user).includes(:supported_permissions), user)
    end

    def zip_permissions(applications, user)
      permissions = Permission.where(:user_id => user.id).includes(:application)
      applications.map do |application|
        [application,
          permissions.detect { |p| p.application_id == application.id } ||
          Permission.new(application_id: application.id, user_id: user.id)]
      end
    end

    # The UI presents the "signin" permission as a dedicated checkbox, even
    # though it is stored as another string in the permissions field in the
    # permissions table.
    #
    # To make this work, we have to process the params, removing the signin
    # checkbox parameter and adding it to the array of permissions.
    def translate_faux_signin_permission(raw_user_params)
      user_params = (raw_user_params || {}).dup
      if user_params[:permissions_attributes]
        user_params[:permissions_attributes].each do |index, attributes|
          attributes[:permissions] ||= []
          if attributes[:signin_permission] == "1"
            attributes[:permissions] << "signin"
          else
            has_signin = false
          end
          attributes.delete(:signin_permission)
        end
      end
      user_params
    end
end
