class UserResearchRecruitmentController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def update
    if params[:choice] == "dismiss-banner"
      cookies[:dismiss_user_research_recruitment_banner] = true
      redirect_to root_path
    end
  end
end
