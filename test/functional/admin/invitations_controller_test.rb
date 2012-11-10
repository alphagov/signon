require 'test_helper'

class Admin::InvitationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:user, is_admin: true)
    sign_in @user
  end

  should "disallow access to non-admins" do
    @user.update_column(:is_admin, false)
    get :new
    assert_redirected_to root_path
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
  end
end
