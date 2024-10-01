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

  context "#current_user_organisation_name" do
    should "return current_user's organisation name with abbreviation" do
      organisation = create(:organisation, name: "Handling Ministry", abbreviation: "HM")
      current_user = build(:user, organisation:)
      stubs(:current_user).returns(current_user)

      assert_equal "Handling Ministry - HM", current_user_organisation_name
    end

    should "return helpful message if user has no organisation" do
      current_user = build(:user)
      stubs(:current_user).returns(current_user)

      assert_equal "No organisation", current_user_organisation_name
    end
  end
end
