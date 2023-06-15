require "test_helper"

class RootHelperTest < ActionView::TestCase
  attr_reader :application, :current_user

  setup do
    @application = build(:application)
    @current_user = build(:user)
  end

  context "#gds_only_application_and_non_gds_user?" do
    should "returns false if application is not GDS-only and user belongs to GDS" do
      application.stubs(:gds_only?).returns(false)
      current_user.stubs(:belongs_to_gds?).returns(true)
      assert_not gds_only_application_and_non_gds_user?(application)
    end

    should "returns false if application is not GDS-only and user does not belong to GDS" do
      application.stubs(:gds_only?).returns(false)
      current_user.stubs(:belongs_to_gds?).returns(false)
      assert_not gds_only_application_and_non_gds_user?(application)
    end

    should "returns false if application is GDS-only and user belongs to GDS" do
      application.stubs(:gds_only?).returns(true)
      current_user.stubs(:belongs_to_gds?).returns(true)
      assert_not gds_only_application_and_non_gds_user?(application)
    end

    should "returns true if application is GDS-only and user does not belong to GDS" do
      application.stubs(:gds_only?).returns(true)
      current_user.stubs(:belongs_to_gds?).returns(false)
      assert gds_only_application_and_non_gds_user?(application)
    end
  end
end
