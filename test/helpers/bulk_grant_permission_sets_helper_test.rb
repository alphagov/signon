require "test_helper"

class BulkGrantPermissionSetsHelperTest < ActionView::TestCase
  attr_reader :current_user

  context "#bulk_grant_permission_set_applications" do
    setup do
      @first_application = create(:application, name: "Application A")
      @second_application = create(:application, name: "Application B")
      @retired_application = create(:application, retired: true)
    end

    context "for a superadmin" do
      setup do
        @current_user = create(:superadmin_user)
      end

      should "return all non-retired applications in alphabetical order" do
        assert_equal [@first_application, @second_application], bulk_grant_permission_set_applications
      end
    end

    context "for an admin" do
      setup do
        @current_user = create(:user, role: "admin")
      end

      should "return all non-retired applications in alphabetical order" do
        assert_equal [@first_application, @second_application], bulk_grant_permission_set_applications
      end
    end
  end
end
