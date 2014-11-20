require 'test_helper'

class UserOAuthPresenterTest < ActiveSupport::TestCase

  should "generate JSON" do
    user, app = create(:user), create(:application)
    create(:permission, application: app, user: user, permissions: ["signin", "coughing"])
    justice_league = create(:organisation, slug: "justice-league")
    user.organisation = justice_league

    expected = {
      user: {
        email:  user.email,
        name: user.name,
        uid: user.uid,
        permissions: ["signin", "coughing"],
        organisation_slug: "justice-league",
        disabled: false,
      }
    }

    presenter = UserOAuthPresenter.new(user, app)
    assert_equal(expected, presenter.as_hash)
  end

  should "handle the user having nil permissions value for the app" do
    user, app = create(:user), create(:application)
    create(:permission, application: app, user: user, permissions: nil)

    presenter = UserOAuthPresenter.new(user, app)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end

  should "handle the user having no permissions record for the app" do
    user, app = create(:user), create(:application)

    presenter = UserOAuthPresenter.new(user, app)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end

  should "mark suspended users disabled" do
    suspended_user, app = create(:suspended_user), create(:application)
    create(:permission, application: app, user: suspended_user)

    presenter = UserOAuthPresenter.new(suspended_user, app)
    assert_true presenter.as_hash[:user][:disabled]
  end

  should "exclude permissions if user is suspended" do
    suspended_user, app = create(:suspended_user), create(:application)
    create(:permission, application: app, user: suspended_user, permissions: ["signin", "coughing"])

    presenter = UserOAuthPresenter.new(suspended_user, app)
    assert_empty presenter.as_hash[:user][:permissions]
  end

end
