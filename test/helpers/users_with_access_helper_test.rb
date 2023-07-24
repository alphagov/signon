require "test_helper"

class UsersWithAccessHelperTest < ActionView::TestCase
  test "formatted_user_name links to users with name" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:unusable_account?).returns(false)

    assert_equal '<a href="/users/1/edit">User Name</a>', formatted_user_name(user)
  end

  test "formatted_user_name indicates invited but not accepted accounts" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:invited_but_not_yet_accepted?).returns(true)

    assert_equal '<a href="/users/1/edit">User Name</a> (invited)', formatted_user_name(user)
  end

  test "formatted_user_name indicates suspended accounts" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:suspended?).returns(true)

    assert_equal '<a href="/users/1/edit">User Name</a> (suspended)', formatted_user_name(user)
  end

  test "formatted_user_name indicates access locked accounts" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:access_locked?).returns(true)

    assert_equal '<a href="/users/1/edit">User Name</a> (access locked)', formatted_user_name(user)
  end

  test "formatted_user_name_class is blank for usable accounts" do
    user = build(:user)
    user.stubs(:unusable_account?).returns(false)

    assert user_name_format(user).blank?
  end

  test "formatted_user_name_class strikes through unusable accounts" do
    user = build(:user)
    user.stubs(:unusable_account?).returns(true)

    assert_equal "line-through", user_name_format(user)
  end

  test "formatted_last_sign_in returns the time in words when the user has signed in" do
    user = build(:user)
    user.stubs(:current_sign_in_at).returns(Time.zone.now - 1.second)

    assert_equal "less than a minute ago", formatted_last_sign_in(user)
  end

  test "formatted_last_sign_in indicates if a user has never signed in" do
    user = build(:user)

    assert_equal "never signed in", formatted_last_sign_in(user)
  end
end
