require "test_helper"

class UsersTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?
    $stdout.stubs(:write)

    @user_types = %i[user superadmin_user admin_user organisation_admin super_org_admin]
  end

  context "#set_2sv_by_org" do
    should "sets 2sv for all users within the specified org" do
      organisation = create(:organisation, name: "Department of Health")
      users_in_organisation = @user_types.map { |user_type| create(user_type, organisation:) }
      exempted_user_in_organisation = create(:two_step_exempted_user, organisation:)
      users_in_different_organisation = @user_types.map { |user_type| create(user_type, organisation: create(:organisation)) }

      Rake::Task["users:set_2sv_by_org"].invoke(organisation.name)

      assert users_in_organisation.each(&:reload).all?(&:require_2sv)
      assert_not exempted_user_in_organisation.reload.require_2sv
      assert(users_in_different_organisation.each(&:reload).all? { |user| !user.require_2sv })
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
end
