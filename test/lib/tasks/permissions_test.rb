require "test_helper"

class PermissionsTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @gds_org = create(:gds_organisation)
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

  context "#remove_inappropriately_granted_permissions_from_non_gds_users" do
    setup do
      @task = Rake::Task["permissions:remove_inappropriately_granted_permissions_from_non_gds_users"]

      @collections_publisher = application_with_revoke_and_retain_list(
        name: "Collections publisher",
        non_signin_permissions_to_revoke: [
          "2i reviewer", "Coronavirus editor", "Edit Taxonomy", "GDS Editor", "Livestream editor", "Sidekiq Monitoring", "Skip review", "Unreleased feature"
        ],
        revoke_signin: true,
        retain_non_signin_permission: true,
      )
      @content_data = application_with_revoke_and_retain_list(
        name: "Content Data",
        non_signin_permissions_to_revoke: %w[view_email_subs view_siteimprove],
        retain_non_signin_permission: true,
      )
      @content_tagger = application_with_revoke_and_retain_list(
        name: "Content Tagger",
        non_signin_permissions_to_revoke: ["GDS Editor", "Unreleased feature"],
        retain_non_signin_permission: true,
      )
      @manuals_publisher = application_with_revoke_and_retain_list(name: "Manuals Publisher", non_signin_permissions_to_revoke: %w[gds_editor])
      @specialist_publisher = application_with_revoke_and_retain_list(name: "Specialist Publisher", non_signin_permissions_to_revoke: %w[gds_editor])
      @support = application_with_revoke_and_retain_list(name: "Support", non_signin_permissions_to_revoke: %w[feedex_exporters feedex_reviews])
      @app_to_ignore = application_with_revoke_and_retain_list(name: "Ignore me", non_signin_permissions_to_revoke: [], retain_non_signin_permission: true)

      @non_gds_user_1 = create(
        :user,
        organisation: @non_gds_org,
        with_permissions: all_permissions_by_app([@collections_publisher, @content_data, @content_tagger, @app_to_ignore]),
      )
      @non_gds_user_2 = create(
        :user,
        organisation: @non_gds_org,
        with_permissions: all_permissions_by_app([@content_tagger, @manuals_publisher, @specialist_publisher, @support, @app_to_ignore]),
      )
      @gds_user = create(
        :user,
        organisation: @gds_org,
        with_permissions: all_permissions_by_app([@collections_publisher, @manuals_publisher, @specialist_publisher, @support, @app_to_ignore]),
      )

      @initiator = create(:user, email: "ynda.jas@digital.cabinet-office.gov.uk")
    end

    should "remove inapppropriately-granted permissions from non-GDS users, leaving other permissions in place" do
      string_io = StringIO.new
      string_io.puts "y"
      string_io.rewind
      $stdin = string_io

      @task.invoke

      $stdin = STDIN

      [@collections_publisher, @content_data, @content_tagger, @app_to_ignore].each do |app_hash|
        assert_equal app_hash[:retained_permissions].map(&:name), @non_gds_user_1.permissions_for(app_hash[:application])
        assert_event_logs_for_removal(@non_gds_user_1.uid, app_hash[:revoked_permissions])
        refute_event_logs_for_removal(@non_gds_user_1.uid, app_hash[:retained_permissions])
      end

      [@content_tagger, @manuals_publisher, @specialist_publisher, @support, @app_to_ignore].each do |app_hash|
        assert_equal app_hash[:retained_permissions].map(&:name), @non_gds_user_2.permissions_for(app_hash[:application])
        assert_event_logs_for_removal(@non_gds_user_2.uid, app_hash[:revoked_permissions])
        refute_event_logs_for_removal(@non_gds_user_2.uid, app_hash[:retained_permissions])
      end

      [@collections_publisher, @manuals_publisher, @specialist_publisher, @support, @app_to_ignore].each do |app_hash|
        assert_equal app_hash[:application].supported_permissions.order(:name).pluck(:name), @gds_user.permissions_for(app_hash[:application])
        refute_event_logs_for_removal(@gds_user.uid, app_hash[:application].supported_permissions)
      end
    end
  end

  def all_permissions_by_app(app_hashes)
    permissions_hash = {}

    app_hashes.each do |app_hash|
      application = app_hash[:application]
      permissions_hash[application] = application.supported_permissions.map(&:name)
    end

    permissions_hash
  end

  def application_with_revoke_and_retain_list(name:, non_signin_permissions_to_revoke:, revoke_signin: false, retain_non_signin_permission: false)
    application = create(:application, name:)
    hash = { application:, retained_permissions: [], revoked_permissions: [] }

    signin_permission = hash[:application].signin_permission

    if revoke_signin
      hash[:revoked_permissions].push(signin_permission)
    else
      hash[:retained_permissions].push(signin_permission)
    end

    hash[:retained_permissions].push(create(:supported_permission, application:, name: "Untouchable")) if retain_non_signin_permission
    hash[:revoked_permissions] = non_signin_permissions_to_revoke.sort.map { |permission_name| create(:supported_permission, application:, name: permission_name) }

    hash
  end

  def assert_event_logs_for_removal(grantee_uid, permissions)
    permissions.each do |permission|
      assert_predicate EventLog.where(
        uid: grantee_uid,
        event_id: EventLog::PERMISSIONS_REMOVED.id,
        initiator: @initiator,
        application_id: permission.application_id,
        trailing_message: "(removed inappropriately granted permission from non-GDS user: #{permission.name})",
      ), :one?
    end
  end

  def refute_event_logs_for_removal(grantee_uid, permissions)
    permissions.each do |permission|
      assert_empty EventLog.where(
        uid: grantee_uid,
        event_id: EventLog::PERMISSIONS_REMOVED.id,
        initiator: @initiator,
        application_id: permission.application_id,
        trailing_message: "(removed inappropriately granted permission from non-GDS user: #{permission.name})",
      )
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
