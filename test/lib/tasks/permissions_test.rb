require "test_helper"

class PermissionsTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @gds_org = create(:organisation, name: "Government Digital Service")
    @non_gds_org = create(:organisation, name: "Another Department")
    $stdout.stubs(:write)
  end

  teardown do
    @task.reenable # without this, calling `invoke` does nothing after first test
  end

  context "#promote_managing_editors_to_org_admins" do
    setup do
      @first_app = create(:application, name: "Cat Publisher", with_non_delegatable_supported_permissions: ["Managing Editor", "other"])
      @second_app = create(:application, name: "Dog Publisher", with_non_delegatable_supported_permissions: %w[managing_editor other])
      @task = Rake::Task["permissions:promote_managing_editors_to_org_admins"]
    end

    should "update any non-GDS user with a managing editor permission who is not suspended and has a 'normal' role" do
      first_non_gds_user = user_with_permissions(:user, @non_gds_org, { @first_app => ["Managing Editor"], @second_app => %w[managing_editor other] })
      second_non_gds_user = user_with_permissions(:user, @non_gds_org, { @second_app => %w[managing_editor other] })

      @task.invoke

      assert first_non_gds_user.reload.organisation_admin?
      assert second_non_gds_user.reload.organisation_admin?
    end

    should "not update a non-GDS user without a managing editor permission" do
      non_gds_user = user_with_permissions(:user, @non_gds_org, { @first_app => %w[other], @second_app => %w[other] })

      @task.invoke

      assert non_gds_user.reload.normal?
    end

    should "not update a non-GDS user who already has an admin role" do
      admin_user = user_with_permissions(:admin_user, @non_gds_org, { @first_app => ["Managing Editor"] })

      @task.invoke

      assert admin_user.reload.admin?
    end

    should "not update a non-GDS user who is suspended" do
      user = user_with_permissions(:user, @non_gds_org, { @first_app => ["Managing Editor"] })
      user.update!(suspended_at: 1.day.ago, reason_for_suspension: "Dormant account")

      @task.invoke

      assert user.reload.normal?
    end

    should "not update GDS users" do
      gds_users = %i[user admin_user].map do |user_type|
        user_with_permissions(user_type, @gds_org, { @first_app => ["Managing Editor"] })
      end
      original_roles = gds_users.map(&:role)

      @task.invoke

      gds_users.each(&:reload)
      assert gds_users.map(&:role) == original_roles
    end
  end

  context "#remove_editor_permission_from_whitehall_managing_editors" do
    setup do
      @whitehall_app = create(:application, name: "Whitehall", with_non_delegatable_supported_permissions: ["Editor", "Managing Editor", "Some Other Permission"])
      @task = Rake::Task["permissions:remove_editor_permission_from_whitehall_managing_editors"]
    end

    should "remove Whitehall editor permission from non-GDS managing editors" do
      non_gds_managing_editor_and_editor = user_with_permissions(:user, @non_gds_org, { @whitehall_app => ["Editor", "Managing Editor", "Some Other Permission"] })
      non_gds_managing_editor = user_with_permissions(:user, @non_gds_org, { @whitehall_app => ["Managing Editor", "Some Other Permission"] })

      @task.invoke

      assert_equal non_gds_managing_editor_and_editor.permissions_for(@whitehall_app), ["Managing Editor", "Some Other Permission"]
      assert_equal non_gds_managing_editor.permissions_for(@whitehall_app), ["Managing Editor", "Some Other Permission"]
    end

    should "retain Whitehall editor permission for non-GDS editors without managing editor permission" do
      editor = user_with_permissions(:user, @non_gds_org, { @whitehall_app => ["Editor", "Some Other Permission"] })

      @task.invoke

      assert_equal editor.permissions_for(@whitehall_app), ["Editor", "Some Other Permission"]
    end

    should "retain both permissions for other apps" do
      non_whitehall_app = create(:application, name: "Another App", with_non_delegatable_supported_permissions: ["Editor", "Managing Editor", "Some Other Permission"])
      non_gds_managing_editor_and_editor = user_with_permissions(:user, @non_gds_org, { non_whitehall_app => ["Editor", "Managing Editor", "Some Other Permission"] })

      @task.invoke

      assert_equal non_gds_managing_editor_and_editor.permissions_for(non_whitehall_app), ["Editor", "Managing Editor", "Some Other Permission"]
    end

    should "retain Whitehall editor permission for GDS users" do
      gds_managing_editor_and_editor = user_with_permissions(:user, @gds_org, { @whitehall_app => ["Editor", "Managing Editor", "Some Other Permission"] })

      @task.invoke

      assert_equal gds_managing_editor_and_editor.permissions_for(@whitehall_app), ["Editor", "Managing Editor", "Some Other Permission"]
    end
  end

  def user_with_permissions(user_type, organisation, permissions_hash)
    create(user_type, organisation:).tap do |user|
      permissions_hash.to_a.each do |app, permissions|
        user.grant_application_permissions(app, permissions)
      end
    end
  end
end
