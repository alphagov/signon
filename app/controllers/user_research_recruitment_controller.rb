class UserResearchRecruitmentController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def dismiss_banner
    cookies[:dismiss_user_research_recruitment_banner] = true
    redirect_to root_path
  end
end
