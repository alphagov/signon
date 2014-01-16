require 'test_helper'

class Admin::InvitationsControllerTest < ActionController::TestCase
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
        admin = create(:organisation_admin, with_signin_permissions_for: [ delegatable_app, non_delegatable_app ] )

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

    context "SES has blacklisted the address" do
      should "show the user a helpful message" do
        Devise::Mailer.any_instance.expects(:mail).with(anything)
            .raises(AWS::SES::ResponseError, OpenStruct.new(error: { 'Code' => "MessageRejected", 'Message' => "Address blacklisted." }))

        post :create, user: { name: "John Smith", email: "jsmith@restrictivemailserver.com" }

        assert_response 500
        assert_template "shared/address_blacklisted"
      end
    end

    context "organisation admin" do
      should "not assign organisations not under them" do
        admin = create(:organisation_admin)
        outside_organisation = create(:organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: outside_organisation.id }

        assert_redirected_to root_path
      end

      should "assign only organisations under them" do
        admin = create(:organisation_admin)
        sub_organisation = create(:organisation, parent: admin.organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: sub_organisation.id }

        assert_equal sub_organisation.id, User.last.organisation_id
      end
    end
  end
end
