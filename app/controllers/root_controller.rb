class RequestPathLengthError < RuntimeError; end

class RootController < ApplicationController
  before_action :authenticate_user!, except: %i[privacy_notice accessibility_statement]
  skip_after_action :verify_authorized

  def index
    @applications = Doorkeeper::Application.not_api_only.with_home_uri.can_signin(current_user)
  end

  def signin_required
    @application = Doorkeeper::Application.find_by(id: session.delete(:signin_missing_for_application))
  end

  def privacy_notice; end

  def accessibility_statement; end

private

  def authenticate_user!
    if request.fullpath.bytesize > ActionDispatch::Cookies::MAX_COOKIE_SIZE / 2
      raise RequestPathLengthError, "Request path exceeds maximum length"
    end

    super
  end

  def show_user_research_recruitment_banner?
    Rails.application.config.show_user_research_recruitment_banner &&
      !cookies[:dismiss_user_research_recruitment_banner] &&
      !current_user.user_research_recruitment_banner_hidden?
  end
  helper_method :show_user_research_recruitment_banner?
end
