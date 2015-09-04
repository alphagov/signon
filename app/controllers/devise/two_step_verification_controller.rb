class Devise::TwoStepVerificationController < Devise::TwoFactorAuthenticationController
  def new
    if current_user.otp_secret_key.present?
      redirect_to root_path, alert: "Two Step Verification is already set up"
    else
      @otp_secret_key = ROTP::Base32.random_base32
    end
  end

  def create
    @otp_secret_key = params[:otp_secret_key]
    totp = ROTP::TOTP.new(@otp_secret_key)
    if totp.verify(params[:code])
      current_user.update_attribute(:otp_secret_key, @otp_secret_key)
      redirect_to "/", notice: "Two Step Verification set up"
    else
      flash.now[:alert] = "Invalid Two Step Verification code. Perhaps you entered it incorrectly?"
      render :new
    end
  end
end
