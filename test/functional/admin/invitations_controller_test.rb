require 'test_helper'

class Admin::InvitationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:user, role: "admin")
    sign_in @user
  end

  should "disallow access to non-admins" do
    @user.update_column(:role, 'normal')
    get :new
    assert_redirected_to root_path
  end

  context "GET new" do
    context "organisation admin" do
      should "can select only organisations under him" do
        admin = FactoryGirl.create(:user_in_organisation, role: "organisation_admin")
        sub_organisation = FactoryGirl.create(:organisation, parent: admin.organisation)
        outside_organisation = FactoryGirl.create(:organisation)
        sign_in admin

        with_const_override(:DISABLE_MEMBERSHIP_EDITING, false) do
          get :new

          assert_select ".container" do
            assert_select "option", count: 0, text: outside_organisation.name_with_abbreviation
            assert_select "option", count: 1, text: admin.organisation.name_with_abbreviation
            assert_select "option", count: 1, text: sub_organisation.name_with_abbreviation
          end
        end
      end
    end
  end

  context "POST create" do
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
      should "cannot assign only organisations not under him" do
        admin = FactoryGirl.create(:user_in_organisation, role: "organisation_admin")
        outside_organisation = FactoryGirl.create(:organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: outside_organisation.id }

        assert_redirected_to root_path
      end

      should "can assign only organisations under him" do
        admin = FactoryGirl.create(:user_in_organisation, role: "organisation_admin")
        sub_organisation = FactoryGirl.create(:organisation, parent: admin.organisation)
        sign_in admin

        post :create, user: { name: "John Smith", email: "jsmith@digital.cabinet-office.gov.uk", organisation_id: sub_organisation.id }

        assert_equal sub_organisation.id, User.last.organisation_id
      end
    end
  end
end
