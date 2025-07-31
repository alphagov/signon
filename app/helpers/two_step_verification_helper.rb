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

  def otp_secret_key_uri(user:, otp_secret_key:)
    issuer = I18n.t("devise.issuer")
    unless GovukEnvironment.current == "production"
      issuer = "#{GovukEnvironment.current.titleize} #{issuer}"
    end

    issuer = ERB::Util.url_encode(issuer)
    "otpauth://totp/#{issuer}:#{user.email}?secret=#{otp_secret_key.upcase}&issuer=#{issuer}"
  end

  def qr_code_svg(user:, otp_secret_key:)
    uri = otp_secret_key_uri(user:, otp_secret_key:)
    qr_code = RQRCode::QRCode.new(uri, level: :m)
    qr_code.as_svg(
      use_path: true,
      viewbox: true,
    ).html_safe
  end

  def two_factor_code_input(**args)
    options = {
      label: { text: "Code from app" },
      hint: "Enter 6-digit code",
      name: "code",
      type: "text",
      autocomplete: "one-time-code",
      inputmode: "numeric",
      width: 10,
    }.merge(args)

    GovukPublishingComponents.render("govuk_publishing_components/components/input", options)
  end
end
