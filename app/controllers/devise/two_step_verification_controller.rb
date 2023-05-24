class Devise::TwoStepVerificationController < DeviseController
  before_action -> { authenticate_user!(force: true) }, only: :prompt
  before_action :prepare_and_validate, except: :prompt
  layout "admin_layout", only: %w[prompt]

  attr_reader :otp_secret_key

  def prompt; end

  def show
    generate_secret
  end

  def update
    mode = current_user.has_2sv? ? :change : :setup
    if verify_code_and_update
      EventLog.record_event(current_user, success_event_for(mode), ip_address: user_ip_address)
      send_notification(current_user, mode)
      redirect_to_prior_flow notice: I18n.t("devise.two_step_verification.messages.success.#{mode}")
    else
      EventLog.record_event(current_user, failure_event_for(mode), ip_address: user_ip_address)
      flash.now[:invalid_code] = "Sorry that code didn’t work. Please try again."
      render :show, status: :unprocessable_entity
    end
  end

private

  def send_notification(_user, mode)
    if mode == :setup
      UserMailer.two_step_enabled(current_user).deliver_later
    else
      UserMailer.two_step_changed(current_user).deliver_later
    end
  end

  def qr_code_data_uri
    uri = otp_secret_key_uri(user: current_user, otp_secret_key: @otp_secret_key)
    qr_code = RQRCode::QRCode.new(uri, level: :m)
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

  def generate_secret
    @otp_secret_key = ROTP::Base32.random_base32
  end

  def verify_code_and_update
    @otp_secret_key = params[:otp_secret_key]
    totp = ROTP::TOTP.new(@otp_secret_key)
    if totp.verify(params[:code], drift_behind: User::MAX_2SV_DRIFT_SECONDS)
      current_user.update!(otp_secret_key: @otp_secret_key, reason_for_2sv_exemption: nil, expiry_date_for_2sv_exemption: nil)
      true
    else
      false
    end
  end

  def failure_event_for(mode)
    mode == :setup ? EventLog::TWO_STEP_ENABLE_FAILED : EventLog::TWO_STEP_CHANGE_FAILED
  end

  def success_event_for(mode)
    mode == :setup ? EventLog::TWO_STEP_ENABLED : EventLog::TWO_STEP_CHANGED
  end
end
