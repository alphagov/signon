require "test_helper"

class ApplicationAccessHelperTest < ActionView::TestCase
  setup do
    @application = create(:application, name: "Whitehall")
    stubs(:current_user).returns(create(:user))
  end

  context "#access_granted_description" do
    context "when the user is granting themself access" do
      should "return a message informing them that they have access to an application" do
        assert_equal "You have been granted access to Whitehall.", access_granted_description(@application)
      end
    end

    context "when the user is granting another access" do
      should "return a message informing them that the other user has access to an application" do
        user = create(:user, name: "Gerald")
        assert_equal "Gerald has been granted access to Whitehall.", access_granted_description(@application, user)
      end
    end

    context "when the application does not exist" do
      should "return nil" do
        assert_nil access_granted_description(:made_up_id)
      end
    end
  end
end
