class RootController < ApplicationController
  include UserPermissionsControllerMethods
  before_filter :authenticate_user!
  skip_after_filter :verify_authorized

  def index
    applications = (::Doorkeeper::Application.can_signin(current_user) <<
                    ::Doorkeeper::Application.where(name: 'Support').first).compact.uniq

    @applications_and_permissions = zip_permissions(applications, current_user)
  end
end
