require "test_helper"

class CodeVerifierTest < ActiveSupport::TestCase
  attr_reader :secret

  setup do
    @secret = "topsecret"
  end

  test "#verify" do
    verifier = CodeVerifier.new(valid_code, secret)

    assert verifier.verify
  end

  test "#verify when the code contains additional spaces" do
    valid_code_with_spaces = " #{valid_code[0..2]} #{valid_code[3..5]} "

    verifier = CodeVerifier.new(valid_code_with_spaces, secret)

    assert verifier.verify
  end

  test "#verify when the code contains dashes" do
    valid_code_with_dashes = "#{valid_code[0..2]}-#{valid_code[3..5]}"

    verifier = CodeVerifier.new(valid_code_with_dashes, secret)

    assert verifier.verify
  end

private

  def valid_code
    totp = ROTP::TOTP.new(secret)
    totp.now
  end
end
