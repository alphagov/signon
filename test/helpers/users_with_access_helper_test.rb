require "test_helper"

class UsersWithAccessHelperTest < ActionView::TestCase
  test "formatted_user_name links to users with name" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:unusable_account?).returns(false)

    assert_equal '<a href="/users/1/edit">User Name</a>', formatted_user_name(user)
  end

  test "formatted_user_name indicates unusable accounts with <del> tag" do
    user = build(:user, id: 1, name: "User Name")
    user.stubs(:unusable_account?).returns(true)

    assert_equal '<del><a href="/users/1/edit">User Name</a></del>', formatted_user_name(user)
  end
end
