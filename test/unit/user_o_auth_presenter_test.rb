require 'test_helper'

class UserOAuthPresenterTest < ActiveSupport::TestCase

  setup do
    @application = create(:application, with_supported_permissions: ['managing_editor'])
  end

  should "generate JSON" do
    user, justice_league = create(:user), create(:organisation, slug: "justice-league")
    user.grant_application_permissions(@application, ['signin', 'managing_editor'])
    user.organisation = justice_league

    expected = {
      user: {
        email:  user.email,
        name: user.name,
        uid: user.uid,
        permissions: ["signin", "managing_editor"],
        organisation_slug: "justice-league",
        disabled: false,
      }
    }

    presenter = UserOAuthPresenter.new(user, @application)
    assert_equal(expected, presenter.as_hash)
  end

  should "handle the user having no permissions for the application" do
    user = create(:user)

    presenter = UserOAuthPresenter.new(user, @application)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end

  should "mark suspended users disabled" do
    suspended_user = create(:suspended_user)
    suspended_user.grant_application_permissions(@application, ['signin', 'managing_editor'])

    presenter = UserOAuthPresenter.new(suspended_user, @application)
    assert_true presenter.as_hash[:user][:disabled]
  end

  should "exclude permissions if user is suspended" do
    suspended_user = create(:suspended_user)
    suspended_user.grant_application_permissions(@application, ['signin', 'managing_editor'])

    presenter = UserOAuthPresenter.new(suspended_user, @application)
    assert_empty presenter.as_hash[:user][:permissions]
  end

end
