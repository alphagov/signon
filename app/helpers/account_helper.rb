module AccountHelper
  def two_step_verification_page_title
    if current_user.has_2sv?
      "Change your 2-step verification phone"
    else
      "Set up 2-step verification"
    end
  end
end
