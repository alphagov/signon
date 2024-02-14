require "test_helper"

class UsersFilterTest < ActiveSupport::TestCase
  setup do
    @current_user = User.new
  end

  should "return all users in alphabetical name order" do
    create(:user, name: "beta")
    create(:user, name: "alpha")

    filter = UsersFilter.new(User.all, @current_user)

    assert_equal %w[alpha beta], filter.users.map(&:name)
  end

  should "return pages of users" do
    3.times { create(:user) }

    filter = UsersFilter.new(User.all, @current_user, page: 1, per_page: 2)
    assert_equal 2, filter.paginated_users.count

    filter = UsersFilter.new(User.all, @current_user, page: 2, per_page: 2)
    assert_equal 1, filter.paginated_users.count
  end

  context "when filtering by name or email" do
    should "return users with partially matching name or email" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, @current_user, filter: "does-match")

      assert_equal %w[does-match], filter.users.map(&:name)
    end

    should "ignore leading/trailing spaces in search term" do
      create(:user, name: "does-not-match")
      create(:user, name: "does-match")

      filter = UsersFilter.new(User.all, @current_user, filter: " does-match ")

      assert_equal %w[does-match], filter.users.map(&:name)
    end
  end

  context "when filtering by status" do
    should "return users matching any of the specified statuses" do
      create(:suspended_user, name: "suspended-user")
      create(:invited_user, name: "invited-user")
      create(:locked_user, name: "locked-user")
      create(:active_user, name: "active-user")

      filter = UsersFilter.new(User.all, @current_user, statuses: %w[suspended locked])

      assert_equal %w[locked-user suspended-user], filter.users.map(&:name)
    end
  end

  context "#status_option_select_options" do
    context "when no statuses are selected" do
      should "return options for statuses with none checked" do
        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.status_option_select_options

        expected_options = [
          { label: "Active", value: "active", checked: false },
          { label: "Suspended", value: "suspended", checked: false },
          { label: "Invited", value: "invited", checked: false },
          { label: "Locked", value: "locked", checked: false },
        ]
        assert_equal expected_options, options
      end
    end

    context "when some statuses are selected" do
      should "return options for statuses with relevant options checked" do
        filter = UsersFilter.new(User.all, @current_user, statuses: %w[invited active])
        options = filter.status_option_select_options

        expected_options = [
          { label: "Active", value: "active", checked: true },
          { label: "Suspended", value: "suspended", checked: false },
          { label: "Invited", value: "invited", checked: true },
          { label: "Locked", value: "locked", checked: false },
        ]
        assert_equal expected_options, options
      end
    end
  end

  context "when filtering by 2SV status" do
    should "return users matching any of the specified 2SV statuses" do
      create(:user, name: "not-set-up-user")
      create(:two_step_exempted_user, name: "exempted-user")
      create(:two_step_enabled_user, name: "enabled-user")

      filter = UsersFilter.new(User.all, @current_user, two_step_statuses: %w[not_setup_2sv exempt_from_2sv])

      assert_equal %w[exempted-user not-set-up-user], filter.users.map(&:name)
    end
  end

  context "#two_step_status_option_select_options" do
    context "when no 2SV statuses are selected" do
      should "return options for 2SV statuses with none checked" do
        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.two_step_status_option_select_options

        expected_options = [
          { label: "Enabled", value: "has_2sv", checked: false },
          { label: "Not set up", value: "not_setup_2sv", checked: false },
          { label: "Exempted", value: "exempt_from_2sv", checked: false },
        ]
        assert_equal expected_options, options
      end
    end

    context "when some 2SV statuses are selected" do
      should "return options for statuses with relevant options checked" do
        filter = UsersFilter.new(User.all, @current_user, two_step_statuses: %w[not_setup_2sv exempt_from_2sv])
        options = filter.two_step_status_option_select_options

        expected_options = [
          { label: "Enabled", value: "has_2sv", checked: false },
          { label: "Not set up", value: "not_setup_2sv", checked: true },
          { label: "Exempted", value: "exempt_from_2sv", checked: true },
        ]
        assert_equal expected_options, options
      end
    end
  end

  context "when filtering by role" do
    should "return users matching any of the specified roles" do
      create(:admin_user, name: "admin-user")
      create(:organisation_admin_user, name: "organisation-admin-user")
      create(:user, name: "normal-user")

      filter = UsersFilter.new(User.all, @current_user, roles: %w[admin normal])

      assert_equal %w[admin-user normal-user], filter.users.map(&:name)
    end
  end

  context "#role_option_select_options" do
    context "when no roles are selected" do
      should "return options for roles manageable by the current user with none checked" do
        @current_user.stubs(:manageable_roles).returns([Roles::Normal, Roles::OrganisationAdmin])

        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.role_option_select_options

        expected_options = [
          { label: "Normal", value: "normal", checked: false },
          { label: "Organisation admin", value: "organisation_admin", checked: false },
        ]
        assert_equal expected_options, options
      end
    end

    context "when some roles are selected" do
      should "return options for roles manageable by the current user with relevant options checked" do
        @current_user.stubs(:manageable_roles).returns([Roles::Normal, Roles::OrganisationAdmin, Roles::SuperOrganisationAdmin])

        filter = UsersFilter.new(User.all, @current_user, roles: %w[normal super_organisation_admin])
        options = filter.role_option_select_options

        expected_options = [
          { label: "Normal", value: "normal", checked: true },
          { label: "Organisation admin", value: "organisation_admin", checked: false },
          { label: "Super organisation admin", value: "super_organisation_admin", checked: true },
        ]
        assert_equal expected_options, options
      end
    end
  end

  context "when filtering by permission" do
    should "return users matching any of the specified permissions" do
      app1 = create(:application, name: "App 1")
      app2 = create(:application, name: "App 2")

      permission1 = create(:supported_permission, application: app1, name: "Permission 1")

      create(:user, name: "user1", supported_permissions: [app1.signin_permission, permission1])
      create(:user, name: "user2", supported_permissions: [])
      create(:user, name: "user3", supported_permissions: [app2.signin_permission, permission1])

      filter = UsersFilter.new(User.all, @current_user, permissions: [permission1].map(&:to_param))

      assert_equal %w[user1 user3], filter.users.map(&:name)
    end

    should "return a user once if they have multiple selected permissions for the same app" do
      app = create(:application, name: "App 1")
      permission = create(:supported_permission, application: app, name: "Permission 1")

      create(:user, name: "user", supported_permissions: [app.signin_permission, permission])

      filter = UsersFilter.new(User.all, @current_user, permissions: [app.signin_permission, permission].map(&:to_param))

      assert_equal %w[user], filter.users.map(&:name)
    end
  end

  context "#permission_option_select_options" do
    setup do
      @app1 = create(:application, name: "App 1")
      @app2 = create(:application, name: "App 2")

      @permission1 = create(:supported_permission, application: @app1, name: "Permission 1")
    end

    context "when no permissions are selected" do
      should "return options for application permissions in alphabetical order with none checked" do
        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.permission_option_select_options

        expected_options = [
          { label: "App 1 Permission 1", value: @permission1.to_param, checked: false },
          { label: "App 1 signin", value: @app1.signin_permission.to_param, checked: false },
          { label: "App 2 signin", value: @app2.signin_permission.to_param, checked: false },
        ]

        assert_equal expected_options, options
      end
    end

    context "when some permissions are selected" do
      should "return options for application permissions with relevant options checked" do
        selected_permissions = [@app2.signin_permission, @permission1]
        filter = UsersFilter.new(User.all, @current_user, permissions: selected_permissions.map(&:to_param))
        options = filter.permission_option_select_options

        expected_options = [
          { label: "App 1 Permission 1", value: @permission1.to_param, checked: true },
          { label: "App 1 signin", value: @app1.signin_permission.to_param, checked: false },
          { label: "App 2 signin", value: @app2.signin_permission.to_param, checked: true },
        ]

        assert_equal expected_options, options
      end
    end

    context "when App 2 is retired" do
      setup do
        @app2.update!(retired: true)
      end

      should "return not include options for retired application permissions" do
        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.permission_option_select_options

        app2_option = options.detect { |o| o[:value] == @app2.signin_permission.to_param }
        assert_not app2_option
      end
    end

    context "when App 2 is API-only" do
      setup do
        @app2.update!(api_only: true)
      end

      should "return not include options for API-only application permissions" do
        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.permission_option_select_options

        app2_option = options.detect { |o| o[:value] == @app2.signin_permission.to_param }
        assert_not app2_option
      end
    end
  end

  context "when filtering by organisation" do
    should "return users matching any of the specified organisations" do
      organisation1 = create(:organisation, name: "Organisation 1")
      organisation2 = create(:organisation, name: "Organisation 2")
      organisation3 = create(:organisation, name: "Organisation 3")

      create(:user, name: "user1-in-organisation1", organisation: organisation1)
      create(:user, name: "user2-in-organisation1", organisation: organisation1)
      create(:user, name: "user3-in-organisation2", organisation: organisation2)
      create(:user, name: "user4-in-organisation3", organisation: organisation3)

      filter = UsersFilter.new(User.all, @current_user, organisations: [organisation1, organisation3].map(&:to_param))

      assert_equal %w[user1-in-organisation1 user2-in-organisation1 user4-in-organisation3], filter.users.map(&:name)
    end
  end

  context "#organisation_option_select_options" do
    context "when current user is an admin" do
      setup do
        @organisation = create(:organisation, name: "Org1")
        @current_user = create(:admin_user, organisation: @organisation)
      end

      should "return select options for organisations that have any users" do
        another_organisation = create(:organisation, name: "Org2")
        create(:user, organisation: another_organisation)

        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.organisation_option_select_options

        expected_options = [
          { label: @organisation.name, value: @organisation.to_param, checked: false },
          { label: another_organisation.name, value: another_organisation.to_param, checked: false },
        ]
        assert_equal expected_options, options
      end

      should "return select options with `selected` set appropriately" do
        another_organisation = create(:organisation, name: "Org2")
        create(:user, organisation: another_organisation)

        filter = UsersFilter.new(User.all, @current_user, organisations: [another_organisation.to_param])
        options = filter.organisation_option_select_options

        expected_options = [
          { label: @organisation.name, value: @organisation.to_param, checked: false },
          { label: another_organisation.name, value: another_organisation.to_param, checked: true },
        ]
        assert_equal expected_options, options
      end
    end

    context "when current user is a super organisation admin" do
      setup do
        @organisation = create(:organisation, name: "Org1")
        @current_user = create(:super_organisation_admin_user, organisation: @organisation)
      end

      should "return select options for organisation and sub-organisations that have any users" do
        sub_organisation = create(:organisation, parent: @organisation, name: "Org2")
        create(:organisation, parent: @organisation, name: "Org3")
        create(:user, organisation: sub_organisation)

        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.organisation_option_select_options

        expected_options = [
          { label: @organisation.name, value: @organisation.to_param, checked: false },
          { label: sub_organisation.name, value: sub_organisation.to_param, checked: false },
        ]
        assert_equal expected_options, options
      end
    end

    context "when current user is an organisation admin" do
      setup do
        @organisation = create(:organisation, name: "Org1")
        @current_user = create(:organisation_admin_user, organisation: @organisation)
      end

      should "return select options for only the user's organisation" do
        another_organisation = create(:organisation, name: "Org2")
        create(:user, organisation: another_organisation)

        filter = UsersFilter.new(User.all, @current_user, {})
        options = filter.organisation_option_select_options

        expected_options = [
          { label: @organisation.name, value: @organisation.to_param, checked: false },
        ]
        assert_equal expected_options, options
      end
    end
  end

  context "#no_options_selected_for?" do
    should "return true when there are no options selected for the specified key" do
      filter = UsersFilter.new(User.all, @current_user, {})
      assert filter.no_options_selected_for?(:statuses)
    end

    should "return false when there is at least one option selected for the specified key" do
      filter = UsersFilter.new(User.all, @current_user, { statuses: %w[active] })
      assert_not filter.no_options_selected_for?(:statuses)
    end
  end

  context "#any_options_selected?" do
    should "return true when this is at least one checkbox filter option selected" do
      filter = UsersFilter.new(User.all, @current_user, { statuses: %w[active] })
      assert filter.any_options_selected?
    end

    should "return false when there are no checkbox filter options selected" do
      filter = UsersFilter.new(User.all, @current_user, { filter: "Jill", page: 1, per_page: 25 })
      assert_not filter.any_options_selected?
    end
  end
end
