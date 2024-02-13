require "test_helper"

class UsersTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?
    $stdout.stubs(:write)

    @user_types = %i[user superadmin_user admin_user organisation_admin_user super_organisation_admin_user]
  end

  context "#set_2sv_by_org" do
    should "sets 2sv for all users within the specified org" do
      organisation = create(:organisation, slug: "department-of-health")
      users_in_organisation = @user_types.map { |user_type| create(user_type, organisation:) }
      exempted_user_in_organisation = create(:two_step_exempted_user, organisation:)
      users_in_different_organisation = @user_types.map { |user_type| create(user_type, organisation: create(:organisation)) }

      Rake::Task["users:set_2sv_by_org"].invoke(organisation.slug)

      assert users_in_organisation.each(&:reload).all?(&:require_2sv)
      assert_not exempted_user_in_organisation.reload.require_2sv
      assert(users_in_different_organisation.each(&:reload).all? { |user| !user.require_2sv })
    end
  end

  context "#set_2sv_for_org" do
    should "sets 2sv for the specified org" do
      organisation = create(:organisation, slug: "department-of-health")

      Rake::Task["users:set_2sv_for_org"].invoke(organisation.slug)

      assert organisation.reload.require_2sv?
    end
  end

  context "#set_2sv_by_email_domain" do
    should "sets 2sv for all users within the specified email domain" do
      targeted_domain = "@some.domain.gov.uk"
      other_domain = "@domain.gov.uk"
      users_in_domain = @user_types.map { |user_type| create(user_type, email: user_type.to_s + targeted_domain) }
      exempted_user_in_domain = create(:two_step_exempted_user, email: "exempted_user#{targeted_domain}")
      users_in_other_domain = @user_types.map { |user_type| create(user_type, email: user_type.to_s + other_domain) }

      Rake::Task["users:set_2sv_by_email_domain"].invoke(targeted_domain)

      assert users_in_domain.each(&:reload).all?(&:require_2sv)
      assert_not exempted_user_in_domain.reload.require_2sv
      assert(users_in_other_domain.each(&:reload).all? { |user| !user.require_2sv })
    end
  end

  context "#set_2sv_for_org_admins" do
    setup do
      @task = Rake::Task["users:set_2sv_for_org_admins"]
    end

    teardown do
      @task.reenable # without this, calling `invoke` does nothing after first test
    end

    should "require 2SV for an organisation admin" do
      user = create(:organisation_admin_user)

      @task.invoke

      assert user.reload.require_2sv
    end

    should "require 2SV for an super organisation admin" do
      user = create(:super_organisation_admin_user)

      @task.invoke

      assert user.reload.require_2sv
    end

    should "not require 2SV for normal user" do
      user = create(:user, role: Roles::Normal.role_name)

      @task.invoke

      assert_not user.reload.require_2sv
    end

    should "not reset the existing 2SV key for an organisation admin who already has 2SV enabled" do
      user = create(:two_step_enabled_organisation_admin)
      current_otp_secret_key = user.otp_secret_key

      @task.invoke

      assert user.reload.require_2sv
      assert_equal current_otp_secret_key, user.reload.otp_secret_key
    end
  end
end
