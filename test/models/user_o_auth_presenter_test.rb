require "test_helper"

class UserOAuthPresenterTest < ActiveSupport::TestCase
  setup do
    @application = create(:application, with_supported_permissions: %w[managing_editor])
  end

  should "generate JSON" do
    user = create(:user)
    justice_league = create(:organisation, slug: "justice-league")
    user.grant_application_permissions(@application, %w(signin managing_editor))
    user.organisation = justice_league

    expected_user_attributes = {
      email:  user.email,
      name: user.name,
      uid: user.uid,
      organisation_slug: "justice-league",
      organisation_content_id: justice_league.content_id,
      disabled: false,
    }

    user_representation = UserOAuthPresenter.new(user, @application).as_hash[:user]
    assert_same_elements %w(signin managing_editor), user_representation.delete(:permissions)
    assert_equal expected_user_attributes, user_representation
  end

  should "handle the user having no permissions for the application" do
    user = create(:user)

    presenter = UserOAuthPresenter.new(user, @application)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end

  should "mark suspended users disabled" do
    suspended_user = create(:suspended_user)
    suspended_user.grant_application_permissions(@application, %w(signin managing_editor))

    presenter = UserOAuthPresenter.new(suspended_user, @application)
    assert presenter.as_hash[:user][:disabled]
  end

  should "exclude permissions if user is suspended" do
    suspended_user = create(:suspended_user)
    suspended_user.grant_application_permissions(@application, %w(signin managing_editor))

    presenter = UserOAuthPresenter.new(suspended_user, @application)
    assert_empty presenter.as_hash[:user][:permissions]
  end
end
