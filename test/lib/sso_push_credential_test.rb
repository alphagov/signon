require "test_helper"

class SSOPushCredentialTest < ActiveSupport::TestCase
  setup do
    @application = create(:application, with_supported_permissions: %w[user_update_permission])
    @user = SSOPushCredential.user
  end

  context "given an already authorised application" do
    setup do
      authorisation = @user.authorisations.create!(application_id: @application.id)
      authorisation.update!(token: "foo")
    end

    should "return the bearer token for an already-authorized application" do
      bearer_token = SSOPushCredential.credentials(@application)
      assert_equal "foo", bearer_token
    end

    should "create required application permissions if they do not already exist" do
      assert_equal 0, @user.application_permissions.count

      SSOPushCredential.credentials(@application)

      assert_equal 2, @user.application_permissions.count
      assert_same_elements %w[signin user_update_permission], @user.permissions_for(@application)
    end

    should "not create new application permissions if both already exist" do
      @user.grant_application_permissions(@application, %w[user_update_permission signin])

      assert_equal 2, @user.application_permissions.count
      SSOPushCredential.credentials(@application)

      assert_equal 2, @user.application_permissions.count
      assert_same_elements %w[user_update_permission signin], @user.permissions_for(@application)
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
    SSOPushCredential.credentials(@application)

    assert @user.authorisations.first.present?
    assert @user.authorisations.first.expires_in >= 315_400_000
  end
end
