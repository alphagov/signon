module UserPermissionsControllerMethods
  private
    def applications_and_permissions(user)
      if user.api_user?
        authorised_application_ids = user.authorisations.where(revoked_at: nil).pluck(:application_id)
        applications = ::Doorkeeper::Application.where(id: authorised_application_ids)
      elsif can? :delegate_all_permissions, ::Doorkeeper::Application
        applications = ::Doorkeeper::Application
      else
        applications = ::Doorkeeper::Application.union_of(current_user, user)
      end
      zip_permissions(applications.includes(:supported_permissions), user)
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
