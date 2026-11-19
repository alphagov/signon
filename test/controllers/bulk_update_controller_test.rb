require "test_helper"

class BulkUpdateControllerTest < ActionController::TestCase
  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    context "GET index" do
      should "return not authorised response" do
        get :index

        assert_not_authorised
      end
    end
  end

  context "as superadmin" do
    setup do
      @superadmin = create(:superadmin_user)
      sign_in @superadmin
    end

    context "GET index" do
      should "render the menu" do
        get :index
        assert_select "h1", /Bulk update users/
      end
    end
  end
end
