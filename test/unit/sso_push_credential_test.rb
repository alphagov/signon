require 'test_helper'

class SSOPushCredentialTest < ActiveSupport::TestCase

  setup do
    @application = create(:application)

    SSOPushCredential.user_email = nil
    SSOPushCredential.user = nil
  end

  teardown do
    SSOPushCredential.user_email = nil
    SSOPushCredential.user = nil
  end

  context "given an existing user" do
    setup do
      @user = create(:user, email: "sso-push-user@gov.uk")
      SSOPushCredential.user_email = "sso-push-user@gov.uk"
    end

    context "given an already authorised application" do
      setup do
        authorisation = @user.authorisations.create!(:application_id => @application.id)
        authorisation.update_attribute(:token, "foo")
      end

      should "return the bearer token for an already-authorized application" do
        bearer_token = SSOPushCredential.credentials(@application)
        assert_equal "foo", bearer_token
      end

      should "create required permissions if they do not already exist" do
        assert_equal 0, @user.permissions.count

        SSOPushCredential.credentials(@application)

        assert_equal 1, @user.permissions.count
        assert_equal ["signin", "user_update_permission"], @user.permissions.first.permissions
        assert_equal @application.id, @user.permissions.first.application_id
      end

      should "not create a new permission if both already exist" do
        @user.grant_permissions(@application, ["user_update_permission", "signin"])

        assert_equal 1, @user.permissions.count
        SSOPushCredential.credentials(@application)

        assert_equal 1, @user.permissions.count
        assert_equal ["user_update_permission", "signin"], @user.permissions.first.permissions
        assert_equal @application.id, @user.permissions.first.application_id
      end

      should "update the existing permission if it does not include all the require permissions" do
        @user.grant_permission(@application, "user_update_permission")

        assert_equal 1, @user.permissions.count
        SSOPushCredential.credentials(@application)

        assert_equal 1, @user.permissions.count
        assert_equal ["user_update_permission", "signin"], @user.permissions.first.permissions
        assert_equal @application.id, @user.permissions.first.application_id
      end
    end

    should "create an authorisation if one does not already exist" do
      assert_equal 0, @user.authorisations.count

      bearer_token = SSOPushCredential.credentials(@application)

      assert_equal 1, @user.authorisations.count
      assert_equal bearer_token, @user.authorisations.first.token
      assert_equal @application.id, @user.authorisations.first.application_id
    end

    should "create an authentication with an expiry of 10 years" do
      bearer_token = SSOPushCredential.credentials(@application)

      assert @user.authorisations.first.present?
      assert @user.authorisations.first.expires_in >= 315400000
    end
  end

  context "given an email which does not exist" do
    setup do
      SSOPushCredential.user_email = "does-not-exist@gov.uk"
    end

    should "raise an exception on an authentication attempt" do
      assert_raise SSOPushCredential::UserNotFound do
        SSOPushCredential.credentials(@application)
      end
    end
  end

  context "given no user email" do
    setup do
      SSOPushCredential.user_email = nil
    end

    should "raise an exception on an authentication attempt" do
      assert_raise SSOPushCredential::UserNotProvided do
        SSOPushCredential.credentials(@application)
      end
    end
  end

end
