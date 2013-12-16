module UserPermissionsControllerMethods
  private
    def applications_and_permissions(user)
      if can? :delegate_all_permissions, ::Doorkeeper::Application
        applications = ::Doorkeeper::Application.all
      else
        applications = ::Doorkeeper::Application.can_signin(current_user).with_signin_delegatable
      end
      zip_permissions(applications, user)
    end

    def zip_permissions(applications, user)
      applications.map { |a| [a, Permission.where(application_id: a.id, user_id: user.id).first_or_initialize] }
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
