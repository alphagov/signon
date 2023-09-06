require "test_helper"

class UsersFilterTest < ActiveSupport::TestCase
  setup do
    @current_user = User.new
  end

  should "return all users in alphabetical name order" do
    create(:user, name: "beta")
    create(:user, name: "alpha")

    filter = UsersFilter.new(User.all, @current_user)

    assert_equal %w[alpha beta], filter.users.map(&:name)
  end

  should "return pages of users" do
    3.times { create(:user) }

    filter = UsersFilter.new(User.all, @current_user, page: 1, per_page: 2)
    assert_equal 2, filter.paginated_users.count

    filter = UsersFilter.new(User.all, @current_user, page: 2, per_page: 2)
    assert_equal 1, filter.paginated_users.count
  end

  context "when filtering by name or email" do
    should "return users with partially matching name or email" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, @current_user, filter: "does-match")

      assert_equal %w[does-match], filter.users.map(&:name)
    end

    should "ignore leading/trailing spaces in search term" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, @current_user, filter: " does-match ")

      assert_equal %w[does-match], filter.users.map(&:name)
    end
  end

  context "when filtering by role" do
    should "return users matching any of the specified roles" do
      create(:admin_user, name: "admin-user")
      create(:organisation_admin_user, name: "organisation-admin-user")
      create(:user, name: "normal-user")

      filter = UsersFilter.new(User.all, @current_user, roles: %w[admin normal])

      assert_equal %w[admin-user normal-user], filter.users.map(&:name)
    end
  end

  context "#role_option_select_options" do
    context "when no roles are selected" do
      should "return options for roles manageable by the current user with none checked" do
        @current_user.stubs(:manageable_roles).returns(%w[normal organisation_admin])

        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.role_option_select_options

        expected_options = [
          { label: "Normal", value: "normal", checked: false },
          { label: "Organisation admin", value: "organisation_admin", checked: false },
        ]
        assert_equal expected_options, options
      end
    end

    context "when some roles are selected" do
      should "return options for roles manageable by the current user with relevant options checked" do
        @current_user.stubs(:manageable_roles).returns(%w[normal organisation_admin super_organisation_admin])

        filter = UsersFilter.new(User.all, @current_user, roles: %w[normal super_organisation_admin])
        options = filter.role_option_select_options

        expected_options = [
          { label: "Normal", value: "normal", checked: true },
          { label: "Organisation admin", value: "organisation_admin", checked: false },
          { label: "Super organisation admin", value: "super_organisation_admin", checked: true },
        ]
        assert_equal expected_options, options
      end
    end
  end
end
