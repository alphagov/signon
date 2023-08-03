class RootController < ApplicationController
  layout "admin_layout"

  include UserPermissionsControllerMethods
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def index
    applications = ::Doorkeeper::Application.where(show_on_dashboard: true).can_signin(current_user)

    @applications_and_permissions = zip_permissions(applications, current_user)
  end

  def signin_required
    @application = ::Doorkeeper::Application.find_by(id: session.delete(:signin_missing_for_application))
  end

  def dismiss_user_research_recruitment_banner
    cookies[:dismiss_user_research_recruitment_banner] = true
    redirect_to root_path
  end

private

  def show_user_research_recruitment_banner?
    !cookies[:dismiss_user_research_recruitment_banner]
  end
  helper_method :show_user_research_recruitment_banner?
end
