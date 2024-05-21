require "test_helper"

class OrganisationsControllerTest < ActionController::TestCase
  setup do
    @user = create(:admin_user)
    sign_in @user
  end

  context "GET index" do
    setup do
      create(:organisation, name: "Ministry of Funk", abbreviation: "MoF")
    end

    should "list organisations" do
      get :index
      assert_response :ok
      assert_select "td", "Ministry of Funk (MoF)"
    end
  end

  context "PUT require 2sv" do
    context "when logged in as a super admin" do
      setup do
        super_admin = create(:superadmin_user)
        sign_in super_admin
      end

      should "set require 2sv to true" do
        organisation = create(:organisation, name: "Ministry of Funk")
        put :update, params: { id: organisation.id, organisation: { require_2sv: "1" } }
        assert organisation.reload.require_2sv?
      end

      should "set require 2sv to false when the request does not contain the relevant parameters" do
        organisation = create(:organisation, name: "Ministry of Funk", require_2sv: true)
        put :update, params: { id: organisation.id }
        assert_not organisation.reload.require_2sv?
      end
    end

    context "when logged in as a user with a role other than super admin" do
      setup do
        admin = create(:admin_user)
        sign_in admin
      end

      should "not be allowed to set require 2sv to true" do
        organisation = create(:organisation, name: "Ministry of Funk")
        put :update, params: { id: organisation.id, organisation: { require_2sv: "1" } }
        assert_not_authorised
        assert_not organisation.reload.require_2sv?
      end

      should "not be allowed to set require 2sv to false" do
        organisation = create(:organisation, name: "Ministry of Funk", require_2sv: true)
        put :update, params: { id: organisation.id }
        assert_not_authorised
        assert organisation.reload.require_2sv?
      end
    end
  end
end
