require "test_helper"

class UsersFilterTest < ActiveSupport::TestCase
  should "return all users in alphabetical name order" do
    create(:user, name: "beta")
    create(:user, name: "alpha")

    filter = UsersFilter.new(User.all)

    assert_equal %w[alpha beta], filter.users.map(&:name)
  end

  should "return pages of users" do
    3.times { create(:user) }

    filter = UsersFilter.new(User.all, page: 1, per_page: 2)
    assert_equal 2, filter.paginated_users.count

    filter = UsersFilter.new(User.all, page: 2, per_page: 2)
    assert_equal 1, filter.paginated_users.count
  end
end
