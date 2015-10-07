module TwoStepVerificationHelper
  private

  def handle_two_step_verification
    if signed_in?(:user) && warden.session(:user)['need_two_step_verification']
      handle_failed_second_step
    end
  end

  def handle_failed_second_step
    if request.format.present? && request.format.html?
      session["user_return_to"] = request.original_fullpath if request.get?
      redirect_to new_two_step_verification_session_path
    else
      render nothing: true, status: :unauthorized
    end
  end
end
