require "test_helper"

class UserUpdatePermissionBuilderTest < ActiveSupport::TestCase
  def setup
    application = create(:application)
    create(:supported_permission, application:, name: "perm-1")
    @user = create(:user, with_permissions: { application => %w[perm-1] })
    @existing_permission_id = @user.supported_permissions.first.id
  end

  context "#build" do
    should "should return users existing permission if not updatable and not selected" do
      builder = UserUpdatePermissionBuilder.new(
        user: @user,
        updatable_permission_ids: [],
        selected_permission_ids: [],
      )

      assert_equal [@existing_permission_id], builder.build
    end

    should "should remove users existing permission if updatable and not selected" do
      builder = UserUpdatePermissionBuilder.new(
        user: @user,
        updatable_permission_ids: [@existing_permission_id],
        selected_permission_ids: [],
      )

      assert_equal [], builder.build
    end

    should "should add new permission if updatable and selected" do
      builder = UserUpdatePermissionBuilder.new(
        user: @user,
        updatable_permission_ids: [1],
        selected_permission_ids: [1],
      )

      assert_equal [1, @existing_permission_id].sort, builder.build
    end

    should "should not add new permission if updatable and not selected" do
      builder = UserUpdatePermissionBuilder.new(
        user: @user,
        updatable_permission_ids: [1],
        selected_permission_ids: [],
      )

      assert_equal [@existing_permission_id], builder.build
    end

    should "should not add new permission if not updatable" do
      builder = UserUpdatePermissionBuilder.new(
        user: @user,
        updatable_permission_ids: [1],
        selected_permission_ids: [2],
      )

      assert_equal [@existing_permission_id], builder.build
    end
  end
end
