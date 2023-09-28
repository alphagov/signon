require "test_helper"

class AccountHelperTest < ActionView::TestCase
  context "#two_step_verification_page_title" do
    should "say 'change' if current_user already has 2SV setup" do
      user = build(:two_step_enabled_user)
      stubs(:current_user).returns(user)

      assert_equal "Change your 2-step verification phone", two_step_verification_page_title
    end

    should "say 'set up' if current_user doesn't have 2SV setup already" do
      user = build(:user)
      stubs(:current_user).returns(user)

      assert_equal "Set up 2-step verification", two_step_verification_page_title
    end
  end
end
