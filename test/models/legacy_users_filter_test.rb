require "test_helper"

class LegacyUsersFilterTest < ActiveSupport::TestCase
  context "#redirect?" do
    should "return true if there are any legacy filter params" do
      filter = LegacyUsersFilter.new({ status: User::USER_STATUS_ACTIVE })

      assert filter.redirect?
    end

    should "return false if there are no legacy filter params" do
      filter = LegacyUsersFilter.new({ non_legacy_filter_key: 456 })

      assert_not filter.redirect?
    end
  end

  context "#options" do
    should "transform status legacy filter -> statuses array" do
      filter = LegacyUsersFilter.new({ status: User::USER_STATUS_ACTIVE })

      assert_equal({ statuses: [User::USER_STATUS_ACTIVE] }, filter.options)
    end

    should "transform two_step_status legacy filter -> two_step_statuses array when value is 'true'" do
      filter = LegacyUsersFilter.new({ two_step_status: "true" })

      assert_equal({ two_step_statuses: [User::TWO_STEP_STATUS_ENABLED] }, filter.options)
    end

    should "transform two_step_status legacy filter -> two_step_statuses array when value is 'false'" do
      filter = LegacyUsersFilter.new({ two_step_status: "false" })

      assert_equal({ two_step_statuses: [User::TWO_STEP_STATUS_NOT_SET_UP] }, filter.options)
    end

    should "transform two_step_status legacy filter -> two_step_statuses array when value is 'exempt'" do
      filter = LegacyUsersFilter.new({ two_step_status: "exempt" })

      assert_equal({ two_step_statuses: [User::TWO_STEP_STATUS_EXEMPTED] }, filter.options)
    end

    should "transform role legacy filter -> roles array" do
      filter = LegacyUsersFilter.new({ role: Roles::Admin.name })

      assert_equal({ roles: [Roles::Admin.name] }, filter.options)
    end

    should "transform organisation legacy filter -> organisations array" do
      organisation = create(:organisation)
      filter = LegacyUsersFilter.new({ organisation: organisation.to_param })

      assert_equal({ organisations: [organisation.to_param] }, filter.options)
    end

    should "transform permission legacy filter -> permissions array" do
      permission = create(:supported_permission)
      filter = LegacyUsersFilter.new({ permission: permission.to_param })

      assert_equal({ permissions: [permission.to_param] }, filter.options)
    end
  end
end
