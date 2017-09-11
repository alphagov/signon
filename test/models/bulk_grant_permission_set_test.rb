require 'test_helper'

class BulkGrantPermissionSetTest < ActiveSupport::TestCase
  setup do
    @app = create(:application)
    @permission_set = create(:bulk_grant_permission_set, with_permissions: [@app.signin_permission])
  end

  should "require a user" do
    permission_set = build(:bulk_grant_permission_set, user: nil)

    refute permission_set.valid?
    assert_equal ["can't be blank"], permission_set.errors[:user]
  end

  should "require at least one supported permission" do
    permission_set = build(:bulk_grant_permission_set, with_permissions: [])

    refute permission_set.valid?
    assert_equal ["must not be blank. Choose at least one permission to grant to all users."], permission_set.errors[:supported_permissions]
  end

  context "validating #outcome" do
    should "allow nil" do
      permission_set = build(:bulk_grant_permission_set, outcome: nil)

      assert permission_set.valid?
    end

    should "allow 'success'" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'success')

      assert permission_set.valid?
    end

    should "allow 'fail'" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'fail')

      assert permission_set.valid?
    end

    should "reject other values" do
      permission_set = build(:bulk_grant_permission_set, outcome: 'unsucessful')

      refute permission_set.valid?
      assert_equal ["is not included in the list"], permission_set.errors[:outcome]
    end
  end

  context "perform" do
    should "grant the supplied permissions to all users" do
      user = create(:user)
      admin_user = create(:admin_user)
      superadmin_user = create(:superadmin_user)
      orgadmin_user = create(:organisation_admin)

      @permission_set.perform

      assert_equal %w(signin), user.permissions_for(@app)
      assert_equal %w(signin), admin_user.permissions_for(@app)
      assert_equal %w(signin), superadmin_user.permissions_for(@app)
      assert_equal %w(signin), orgadmin_user.permissions_for(@app)
    end

    should "record the total number of users to be processed" do
      create_list(:user, 4)

      @permission_set.perform

      # we created 4 but there's already one for the permission_set's own user
      assert_equal 5, @permission_set.reload.total_users
    end

    should "record the outcome against the BulkGrantPermissionSet" do
      @permission_set.perform
      assert_equal "success", @permission_set.outcome
    end

    should "record the total number of users that actually were processed" do
      create_list(:user, 4)

      @permission_set.perform

      # we created 4 but there's already one for the permission_set's own user
      assert_equal 5, @permission_set.reload.processed_users
    end

    should "not fail if a user already has one of the supplied permissions" do
      user = create(:user, with_permissions: { @app => %w(signin) })

      @permission_set.perform

      assert_equal %w(signin), user.permissions_for(@app)
    end

    should "not remove permissions a user has that are not part of the supplied ones for the bulk grant set" do
      other_app = create(:application, with_supported_permissions: %w(editor))
      create(:supported_permission, application: @app, name: 'admin')
      user = create(:user, with_permissions: { other_app => %w(editor), @app => %w(admin) })

      @permission_set.perform

      assert_equal %w(editor), user.permissions_for(other_app)
      assert_equal %w(signin admin).sort, user.permissions_for(@app).sort
    end

    should "mark it as failed if there is an error during processing and pass the error on for the worker to record the error details" do
      UserApplicationPermission.any_instance.stubs(:save!).raises("ArbitraryError")

      assert_raises RuntimeError, "ArbitraryError" do
        @permission_set.perform
      end
      assert_equal "fail", @permission_set.outcome
    end

    should "mark how many users it managed to process if it fails" do
      create_list(:user, 4)
      UserApplicationPermission.any_instance.stubs(:save!).returns(true).then.returns(true).then.raises("ArbitraryError")

      assert_raises RuntimeError, "ArbitraryError" do
        @permission_set.perform
      end
      assert_equal 2, @permission_set.reload.processed_users
    end

    context 'recording events against users' do
      setup do
        @app2 = create(:application, with_supported_permissions: %w(signin editor))
        @permission_set.supported_permissions += @app2.supported_permissions
        @permission_set.save!
      end

      should 'record a permissions added event for each app that we grant permissions for' do
        user = create(:user)
        user.event_logs.destroy_all
        @permission_set.perform

        recorded_events = user.event_logs
        assert_equal 2, recorded_events.length

        assert_equal EventLog::PERMISSIONS_ADDED, recorded_events[0].entry
        assert_equal @app2, recorded_events[0].application
        assert_equal '(editor, signin)', recorded_events[0].trailing_message

        assert_equal EventLog::PERMISSIONS_ADDED, recorded_events[1].entry
        assert_equal @app, recorded_events[1].application
        assert_equal '(signin)', recorded_events[1].trailing_message
      end

      should 'not include a permission in the event if the user already has it' do
        user = create(:user, with_permissions: { @app2 => %w(editor) })
        user.event_logs.destroy_all
        @permission_set.perform

        recorded_events = user.event_logs
        assert_equal 2, recorded_events.length

        assert_equal EventLog::PERMISSIONS_ADDED, recorded_events[0].entry
        assert_equal @app2, recorded_events[0].application
        assert_equal '(signin)', recorded_events[0].trailing_message
      end

      should 'not create an event log for the app if the user already has all the permissions we are trying to grant for that app' do
        user = create(:user, with_permissions: { @app => %w(signin) })
        user.event_logs.destroy_all
        @permission_set.perform

        recorded_events = user.event_logs
        assert_equal 1, recorded_events.length

        assert_equal EventLog::PERMISSIONS_ADDED, recorded_events[0].entry
        assert_equal @app2, recorded_events[0].application
      end

      should 'not create any event logs if the user already has all the permissions we are trying to grant' do
        user = create(:user, with_permissions: { @app => %w(signin), @app2 => %w(signin editor) })
        user.event_logs.destroy_all
        @permission_set.perform

        recorded_events = user.event_logs
        assert_equal 0, recorded_events.length
      end
    end
  end
end
