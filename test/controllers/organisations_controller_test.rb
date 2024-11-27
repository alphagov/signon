require "test_helper"

class OrganisationsControllerTest < ActionController::TestCase
  setup do
    @user = create(:admin_user)
    sign_in @user
  end

  context "GET index" do
    should "list organisations in separate tabs for active and closed" do
      active_organisation = create(:organisation)
      closed_organisation = create(:organisation, closed: true)

      get :index

      assert_select "#active td", text: active_organisation.name
      assert_select "#active td", text: closed_organisation.name, count: 0

      assert_select "#closed td", text: active_organisation.name, count: 0
      assert_select "#closed td", text: closed_organisation.name
    end

    should "list organisations in alphabetical order" do
      create(:organisation, name: "Government Digital Service")
      create(:organisation, name: "Cabinet Office")
      create(:organisation, name: "Department for Education")

      get :index

      assert_select "#active tr:first-child td:first-child", text: /Cabinet Office/
      assert_select "#active tr:nth-child(2) td:first-child", text: /Department for Education/
      assert_select "#active tr:last-child td:first-child", text: /Government Digital Service/
    end

    should "include parent organisation when one exists" do
      parent = create(:organisation, name: "Cabinet Office")
      create(:organisation, name: "Government Digital Service", parent:)

      get :index

      assert_select "#active tr:last-child td:first-child", text: /Government Digital Service/
      assert_select "#active tr:last-child td:nth-child(4)", text: /Cabinet Office/
    end

    should "not include parent organisation when one does not exist" do
      parent = create(:organisation, name: "Cabinet Office")
      create(:organisation, name: "Government Digital Service", parent:)

      get :index

      assert_select "#active tr:first-child td:first-child", text: /Cabinet Office/
      assert_select "#active tr:first-child td:nth-child(4)", text: /No parent/
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
