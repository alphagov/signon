module UserPermissionsControllerMethods
  private
    def applications_and_permissions(user)
      ::Doorkeeper::Application.order(:name).all.map do |application|
        permission_for_application = user.permissions.find_or_create_by_application_id(application.id)
        [application, permission_for_application]
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
        end
      end
      user_params
    end
end
