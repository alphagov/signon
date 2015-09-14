module TwoStepVerificationHelper
  private

  def handle_two_step_verification
    if signed_in?(:user) and warden.session(:user)['need_two_step_verification']
      handle_failed_second_step
    end
  end

  def handle_failed_second_step
    if request.format.present? and request.format.html?
      session["user_return_to"] = request.original_fullpath if request.get?
      redirect_to two_step_verification_path
    else
      render nothing: true, status: :unauthorized
    end
  end
end
