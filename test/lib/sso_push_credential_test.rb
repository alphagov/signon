require "test_helper"

class SSOPushCredentialTest < ActiveSupport::TestCase
  setup do
    @application = create(:application, with_non_delegatable_supported_permissions: %w[user_update_permission])
    @user = SSOPushCredential.user
  end

  context "given an already authorised application" do
    setup do
      @authorisation = @user.authorisations.create!(application_id: @application.id, expires_in: 5.weeks)
    end

    should "return the bearer token for an already-authorized application" do
      bearer_token = SSOPushCredential.credentials(@application)
      assert_equal @authorisation.token, bearer_token
    end

    should "create required application permissions if they do not already exist" do
      assert_equal 0, @user.application_permissions.count

      SSOPushCredential.credentials(@application)

      assert_equal 2, @user.application_permissions.count
      assert_same_elements [SupportedPermission::SIGNIN_NAME, "user_update_permission"], @user.permissions_for(@application)
    end

    should "not create new application permissions if both already exist" do
      @user.grant_application_signin_permission(@application)
      @user.grant_application_permissions(@application, %w[user_update_permission])

      assert_equal 2, @user.application_permissions.count
      SSOPushCredential.credentials(@application)

      assert_equal 2, @user.application_permissions.count
      assert_same_elements ["user_update_permission", SupportedPermission::SIGNIN_NAME], @user.permissions_for(@application)
    end
  end

  context "given an application with an authorisation close to expiry" do
    setup do
      @user.authorisations.create!(application_id: @application.id, expires_in: 4.weeks)
    end

    should "create a new authorisation to replace the expired one" do
      bearer_token = SSOPushCredential.credentials(@application)

      new_authorisation = @user.authorisations.find_by(token: bearer_token)
      assert new_authorisation.expires_at > 4.weeks.from_now
      assert_equal @application.id, new_authorisation.application_id
    end
  end

  context "given an application with a revoked authorisation" do
    setup do
      @user.authorisations.create!(application_id: @application.id, revoked_at: Time.current)
    end

    should "create a new authorisation to replace the revoked one" do
      bearer_token = SSOPushCredential.credentials(@application)

      new_authorisation = @user.authorisations.find_by(token: bearer_token)
      assert_nil new_authorisation.revoked_at
      assert_equal @application.id, new_authorisation.application_id
    end
  end

  context "given an application with an expired authorisation" do
    setup do
      travel(-1.day) do
        @user.authorisations.create!(application_id: @application.id, expires_in: 0)
      end
    end

    should "create a new authorisation to replace the expired one" do
      bearer_token = SSOPushCredential.credentials(@application)

      new_authorisation = @user.authorisations.find_by(token: bearer_token)
      assert new_authorisation.expires_at > Time.current
      assert_equal @application.id, new_authorisation.application_id
    end
  end

  context "given a retired application" do
    setup do
      @application.update!(retired: true)
    end

    should "not return a token" do
      assert_nil SSOPushCredential.credentials(@application)
    end

    should "not create a new authorisation" do
      SSOPushCredential.credentials(@application)

      assert_empty @user.authorisations
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
