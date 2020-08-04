class Devise::TwoStepVerificationSessionController < DeviseController
  layout "admin_layout"

  before_action { |c| c.authenticate_user! force: true }
  skip_before_action :handle_two_step_verification

  def new; end

  def create
    render(:show) && return if params[:code].nil?

    if current_user.authenticate_otp(params[:code])
      cookies.signed["remember_2sv_session"] = {
        value: {
          user_id: current_user.id,
          valid_until: User::REMEMBER_2SV_SESSION_FOR.from_now,
          secret_hash: Digest::SHA256.hexdigest(current_user.otp_secret_key),
        },
        secure: Rails.env.production?,
        httponly: true,
        expires: User::REMEMBER_2SV_SESSION_FOR.from_now,
      }

      warden.session(:user)["need_two_step_verification"] = false
      bypass_sign_in current_user
      set_flash_message :notice, :success
      redirect_to_prior_flow
      current_user.update!(second_factor_attempts_count: 0)
    else
      flash[:alert] = find_message(:attempt_failed)
      if current_user.max_2sv_login_attempts?
        sign_out(current_user)
        render :max_2sv_login_attempts_reached
      else
        render :new
      end
    end
  end
end
