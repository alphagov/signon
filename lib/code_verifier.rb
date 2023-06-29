class CodeVerifier
  MAX_2SV_DRIFT_SECONDS = 30

  attr_reader :code, :otp_secret_key

  def initialize(code, otp_secret_key)
    @code = code
    @otp_secret_key = otp_secret_key
  end

  def verify
    totp = ROTP::TOTP.new(otp_secret_key)

    totp.verify(clean_code, drift_behind: MAX_2SV_DRIFT_SECONDS)
  end

private

  def clean_code
    code.gsub(/[ -]/, "")
  end
end
