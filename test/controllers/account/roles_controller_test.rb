require "test_helper"

class Account::RolesControllerTest < ActionController::TestCase
  setup do
    @superadmin_user = create(:superadmin_user)
    sign_in @superadmin_user
  end

  context "GET show" do
    should "display form with current role" do
      get :show

      assert_select "form[action='#{account_role_path}']" do
        assert_select "select[name='user[role]']", value: @superadmin_user.role
      end
    end
  end

  context "PUT update" do
    should "display error when validation fails" do
      UserUpdate.stubs(:new).returns(stub("UserUpdate", call: false))

      put :update, params: { user: { role: Roles::Normal.role_name } }

      assert_template :show
      assert_select "*[role='alert']", text: "There was a problem changing your role."
    end
  end
end
