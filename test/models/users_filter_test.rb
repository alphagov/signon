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

  context "when filtering by name or email" do
    should "return users with partially matching name or email" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, filter: "does-match")

      assert_equal %w[does-match], filter.users.map(&:name)
    end

    should "ignore leading/trailing spaces in search term" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, filter: " does-match ")

      assert_equal %w[does-match], filter.users.map(&:name)
    end
  end
end
