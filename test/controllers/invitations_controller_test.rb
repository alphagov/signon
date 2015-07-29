require 'test_helper'

class InvitationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:admin_user)
    sign_in @user
  end

  should "disallow access to non-admins" do
    @user.update_column(:role, 'normal')
    get :new
    assert_redirected_to root_path
  end

  context "GET new" do
    context "organisation admin" do
      should "can select only organisations under them" do
        admin = create(:organisation_admin)
        sub_organisation = create(:organisation, parent: admin.organisation)
        outside_organisation = create(:organisation)
        sign_in admin

        get :new

        assert_select ".container" do
          assert_select "option", count: 0, text: outside_organisation.name_with_abbreviation
          assert_select "option", count: 1, text: admin.organisation.name_with_abbreviation
          assert_select "option", count: 1, text: sub_organisation.name_with_abbreviation
        end
      end
    end

    context "organisation admin" do
      should "can give permissions to only applications where signin is delegatable and they have access to" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: ["signin"])
        non_delegatable_app = create(:application, with_supported_permissions: ['signin'])
        admin = create(:organisation_admin, with_signin_permissions_for: [delegatable_app, non_delegatable_app])

        sign_in admin

        get :new

        assert_select ".container" do
          assert_select "td", { count: 1, text: delegatable_app.name }
          assert_select "td", { count: 0, text: non_delegatable_app.name }
        end
      end
    end
  end

  context "POST create" do
    should "not allow creation of api users" do
      post :create, user: { name: 'Testing APIs', email: 'api@example.com', api_user: true }

      assert_empty User.where(api_user: true)
    end

    should "not error while inviting an existing user" do
      user = create(:user)

      post :create, user: { name: user.name, email: user.email }

      assert_redirected_to users_path
      assert_equal "User already invited. If you want to, you can click 'Resend signup email'.", flash[:alert]
    end

    context "organisation admin" do
      should "not assign organisations not under them" do
        admin = create(:organisation_admin)
        outside_organisation = create(:organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: outside_organisation.id }

        assert_redirected_to root_path
        assert_equal "You do not have permission to perform this action.", flash[:alert]
      end

      should "assign only organisations under them" do
        admin = create(:organisation_admin)
        sub_organisation = create(:organisation, parent: admin.organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: sub_organisation.id }

        assert_redirected_to users_path
        assert_equal "An invitation email has been sent to jsmith@digital.cabinet-office.gov.uk.", flash[:notice]
        assert_equal sub_organisation.id, User.last.organisation_id
      end
    end
  end

  context "POST resend" do
    should "resend account signup email to user" do
      admin = create(:admin_user)
      user = create(:user)
      User.any_instance.expects(:invite!).once
      sign_in admin

      post :resend, id: user.id

      assert_redirected_to users_path
    end
  end
end
