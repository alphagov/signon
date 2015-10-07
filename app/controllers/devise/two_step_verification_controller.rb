class Devise::TwoStepVerificationController < DeviseController
  before_filter :prepare_and_validate, except: [:prompt, :defer]
  skip_before_filter :handle_two_step_verification

  attr_reader :otp_secret_key
  private :otp_secret_key

  def prompt
  end

  def defer
    current_user.defer_two_step_verification
    redirect_to stored_location_for(:user) || :root
  end

  def new
    if current_user.otp_secret_key.present?
      redirect_to root_path, alert: "2-step verification is already set up"
    else
      @otp_secret_key = ROTP::Base32.random_base32
    end
  end

  def create
    @otp_secret_key = params[:otp_secret_key]
    totp = ROTP::TOTP.new(@otp_secret_key)
    if totp.verify(params[:code])
      current_user.update_attribute(:otp_secret_key, @otp_secret_key)
      EventLog.record_event(current_user, EventLog::TWO_STEP_ENABLED)
      redirect_to_prior_flow(notice: "2-step verification set up")
    else
      EventLog.record_event(current_user, EventLog::TWO_STEP_ENABLE_FAILED)
      flash.now[:invalid_code] = "Sorry that code didn’t work. Please try again."
      render :new, status: 422
    end
  end

  def otp_secret_key_uri
    issuer = "GOV.UK%20Signon"
    if Rails.application.config.instance_name
      issuer = "#{Rails.application.config.instance_name.titleize}%20#{issuer}"
    end
    "otpauth://totp/#{issuer}:#{current_user.email}?secret=#{@otp_secret_key.upcase}&issuer=#{issuer}"
  end

  private
  def qr_code_data_uri
    qr_code = RQRCode::QRCode.new(otp_secret_key_uri, level: :m)
    qr_code.as_png(size: 180, fill: ChunkyPNG::Color::TRANSPARENT).to_data_url
  end
  helper_method :qr_code_data_uri

  def prepare_and_validate
    redirect_to(:root) && return if current_user.nil?
    @limit = User::MAX_2SV_LOGIN_ATTEMPTS
    if current_user.max_2sv_login_attempts?
      sign_out(current_user)
      render(:max_2sv_login_attempts_reached) && return
    end
  end
end
