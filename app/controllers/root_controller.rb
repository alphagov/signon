class RootController < ApplicationController
  USER_RESEARCH_RECRUITMENT_FORM_URL = "https://docs.google.com/forms/d/1Bdu_GqOrSR4j6mbuzXkFTQg6FRktRMQc8Y-q879Mny8/viewform".freeze

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

  def user_research_recruitment_form
    current_user.update!(user_research_recruitment_banner_hidden: true)
    redirect_to USER_RESEARCH_RECRUITMENT_FORM_URL, allow_other_host: true
  end

private

  def show_user_research_recruitment_banner?
    !cookies[:dismiss_user_research_recruitment_banner] && !current_user.user_research_recruitment_banner_hidden?
  end
  helper_method :show_user_research_recruitment_banner?
end
