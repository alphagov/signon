class UserResearchRecruitmentController < ApplicationController
  USER_RESEARCH_RECRUITMENT_FORM_URL = "https://docs.google.com/forms/d/1Bdu_GqOrSR4j6mbuzXkFTQg6FRktRMQc8Y-q879Mny8/viewform".freeze

  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def dismiss_banner
    cookies[:dismiss_user_research_recruitment_banner] = true
    redirect_to root_path
  end

  def participate
    current_user.update!(user_research_recruitment_banner_hidden: true)
    redirect_to USER_RESEARCH_RECRUITMENT_FORM_URL, allow_other_host: true
  end
end
