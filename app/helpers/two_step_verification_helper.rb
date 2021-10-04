module TwoStepVerificationHelper
private

  def handle_two_step_verification
    # TODO: Should raise error if this helper is reached and not already signed in.
    return unless signed_in?(:user)

    if warden.session(:user)["need_two_step_verification"]
      handle_failed_second_step
    elsif current_user.prompt_for_2sv? && !on_2sv_setup_journey
      # NOTE: 'Prompt' means prompt the user to _set up_ 2SV.
      redirect_to prompt_two_step_verification_path
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

  def on_2sv_setup_journey
    controller_path == Devise::TwoStepVerificationController.controller_path
  end
end
