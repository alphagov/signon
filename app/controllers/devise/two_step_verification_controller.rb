class Devise::TwoStepVerificationController < Devise::TwoFactorAuthenticationController
  attr_reader :otp_secret_key
  private :otp_secret_key

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
      redirect_to "/", notice: "2-step verification set up"
    else
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
end
