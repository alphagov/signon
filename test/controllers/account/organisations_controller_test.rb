require "test_helper"

class Account::OrganisationsControllerTest < ActionController::TestCase
  setup do
    @organisation = create(:organisation)
    create(:organisation)
    @superadmin_user = create(:superadmin_user)
    sign_in @superadmin_user
  end

  context "GET show" do
    should "display form with current organisation" do
      get :show

      assert_select "form[action='#{account_organisation_path}']" do
        assert_select "select[name='user[organisation_id]']", value: @superadmin_user.organisation_id
      end
    end
  end

  context "PUT update" do
    should "display error when validation fails" do
      UserUpdate.stubs(:new).returns(stub("UserUpdate", call: false))

      put :update, params: { user: { organisation_id: @organisation } }

      assert_template :show
      assert_select "*[role='alert']", text: "There was a problem changing your organisation."
    end
  end
end
