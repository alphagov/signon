require "test_helper"

class PermissionsPromoterTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @gds_org = create(:organisation, name: "Government Digital Service")
    @org = create(:organisation, name: "Another Department")
    @first_app = create(:application, name: "Cat Publisher", with_supported_permissions: ["Managing Editor", "other"])
    @second_app = create(:application, name: "Dog Publisher", with_supported_permissions: %w[managing_editor other])
    @task = Rake::Task["permissions_promoter:promote_managing_editors_to_org_admins"]
    $stdout.stubs(:write)
  end

  teardown do
    @task.reenable # without this, calling `invoke` does nothing after first test
  end

  context "#promote_managing_editors_to_org_admins" do
    should "update any non-GDS user with a managing editor permission who is not suspended and has a 'normal' role" do
      first_non_gds_user = user_with_permissions(:user, @org, { @first_app => ["Managing Editor"], @second_app => %w[managing_editor other] })
      second_non_gds_user = user_with_permissions(:user, @org, { @second_app => %w[managing_editor other] })

      @task.invoke

      users = [first_non_gds_user, second_non_gds_user].each(&:reload)

      users.each do |user|
        assert user.role == Roles::OrganisationAdmin.role_name
      end
    end
  end

  should "not update a non-GDS user without a managing editor permission" do
    non_gds_user = user_with_permissions(:user, @org, { @first_app => %w[other], @second_app => %w[other] })

    @task.invoke

    assert non_gds_user.reload.role == "normal"
  end

  should "not update a non-GDS user who already has an admin role" do
    admin_user = user_with_permissions(:admin_user, @org, { @first_app => ["Managing Editor"] })

    @task.invoke

    assert admin_user.reload.role == Roles::Admin.role_name
  end

  should "not update a non-GDS user who is suspended" do
    user = user_with_permissions(:user, @org, { @first_app => ["Managing Editor"] })
    user.update!(suspended_at: 1.day.ago, reason_for_suspension: "Dormant account")

    @task.invoke

    assert user.reload.role == "normal"
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

  def user_with_permissions(user_type, organisation, permissions_hash)
    create(user_type, organisation:).tap do |user|
      permissions_hash.to_a.each do |app, permissions|
        user.grant_application_permissions(app, permissions)
      end
    end
  end
end
