require 'test_helper'

class UserOAuthPresenterTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  should "generate JSON" do
    app = create(:application)
    create(:permission, application: app, user: @user, permissions: ["signin", "coughing"])
    justice_league = create(:organisation, slug: "justice-league")
    @user.organisation = justice_league

    expected = {
      user: {
        email:  @user.email,
        name: @user.name,
        uid: @user.uid,
        permissions: ["signin", "coughing"],
        organisation_slug: "justice-league",
      }
    }
    presenter = UserOAuthPresenter.new(@user, app)
    assert_equal(expected, presenter.as_hash)
  end

  should "handle the user having nil permissions value for the app" do
    app = create(:application)
    create(:permission, application: app, user: @user, permissions: nil)
    presenter = UserOAuthPresenter.new(@user, app)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end

  should "handle the user having no permissions record for the app" do
    app = create(:application)
    presenter = UserOAuthPresenter.new(@user, app)
    assert_equal([], presenter.as_hash[:user][:permissions])
  end
end
