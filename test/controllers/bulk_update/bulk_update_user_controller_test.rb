require "test_helper"

class BulkUpdate::BulkUpdateUserControllerTest < ActionController::TestCase
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
      should "render form" do
        get :index

        assert_select "form" do
          assert_select "input[type='file'][name='csv_file']"
        end
      end
    end
  end
end
