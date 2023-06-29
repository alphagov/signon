require "test_helper"

class CodeVerifierTest < ActiveSupport::TestCase
  attr_reader :secret

  setup do
    @secret = "topsecret"
  end

  test "#verify" do
    totp = ROTP::TOTP.new(secret)
    valid_code = totp.now

    verifier = CodeVerifier.new(valid_code, secret)

    assert verifier.verify
  end
end
