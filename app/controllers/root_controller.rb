class RootController < ApplicationController
  layout "admin_layout"

  include UserPermissionsControllerMethods
  before_action :authenticate_user!, except: :privacy_notice
  skip_after_action :verify_authorized

  def index
    applications = Doorkeeper::Application.not_api_only.with_home_uri.can_signin(current_user)

    @applications_and_permissions = zip_permissions(applications, current_user)
  end

  def signin_required
    @application = Doorkeeper::Application.find_by(id: session.delete(:signin_missing_for_application))
  end

  def privacy_notice; end

private

  def show_user_research_recruitment_banner?
    Rails.application.config.show_user_research_recruitment_banner &&
      !cookies[:dismiss_user_research_recruitment_banner] &&
      !current_user.user_research_recruitment_banner_hidden?
  end
  helper_method :show_user_research_recruitment_banner?
end
