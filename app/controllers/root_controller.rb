class RootController < ApplicationController
  include UserPermissionsControllerMethods
  
  before_filter :authenticate_user!

  def index
    @applications_and_permissions = applications_and_permissions(current_user)
        .sort_by { |application, permission| application.name }
        .select { |application, permission| should_list_app?(permission, application) }
  end

  private
    def should_list_app?(permission, application) 
      permission.permissions.include?("signin") || application.name.downcase == "support"
    end
end
