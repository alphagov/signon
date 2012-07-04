module UserPermissionsControllerMethods
  private
    def applications_and_permissions(user)
      ::Doorkeeper::Application.order(:name).all.map do |application|
        permission_for_application = user.permissions.find_by_application_id(application.id)
        permission_for_application ||= Permission.new(application: application, user: user)
        [application, permission_for_application]
      end
    end

      def translate_faux_signin_permission(raw_user_params)
      user_params = raw_user_params.dup
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
