require "test_helper"

class InvitingUsersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  should "ask the invited user to set a password" do
    user = User.invite!(name: "Jim", email: "jim@web.com")
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token)

    fill_in "New password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    fill_in "Confirm new password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    click_button "Save password"

    assert_response_contains("Your password was set successfully.")
  end

  should "require the invited user to sign in after setting their password" do
    user = User.invite!(name: "Neptuno Keighley", email: "neptuno.keighley@office.gov.uk")

    accept_invitation(
      invitation_token: user.raw_invitation_token,
      password: "pretext annoying headpiece waviness header slinky",
    )

    assert_response_contains("Sign in to GOV.UK")

    fill_in "Email", with: "neptuno.keighley@office.gov.uk"
    fill_in "Password", with: "pretext annoying headpiece waviness header slinky"
    click_button "Sign in"

    assert_response_contains("Make your account more secure by setting up 2‑step verification.")
  end

  context "as an admin" do
    setup do
      admin = create(:admin_user)
      visit root_path
      signin_with(admin)
    end

    should "not present the role selector" do
      visit new_user_invitation_path
      assert has_no_select?("Role")
    end

    context "for an organisation without mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user with 2SV selected" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject

          assert has_field?("Mandate 2-step verification for this user")
          check "Mandate 2-step verification for this user"
          click_button "Update user"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Normal.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Make your Signon account more secure", last_email.subject
          assert User.where(email: "fred@example.com", role: Roles::Normal.name).last.require_2sv?
        end
      end

      should "create and notify the user without 2SV selected" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert has_field?("Mandate 2-step verification for this user")
          click_button "Update user"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Normal.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
          assert_equal false, User.where(email: "fred@example.com", role: Roles::Normal.name).last.require_2sv?
        end
      end

      context "for an organisation with mandatory 2SV" do
        setup do
          create(:organisation, name: "Test Organisation with 2SV", require_2sv: true)
        end

        should "create and notify the user" do
          perform_enqueued_jobs do
            visit new_user_invitation_path
            fill_in "Name", with: "Fred Bloggs"
            fill_in "Email", with: "fred@example.com"
            select "Test Organisation with 2SV", from: "Organisation"
            click_button "Create user and send email"

            assert_not_nil User.where(email: "fred@example.com", role: Roles::Normal.name).last
            assert_equal "fred@example.com", last_email.to[0]
            assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
            assert User.where(email: "fred@example.com", role: Roles::Normal.name).last.require_2sv?
          end
        end
      end
    end

    should "resend the invite" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        click_button "Update user"

        user = User.find_by(email: "fred@example.com")
        visit edit_user_path(user)

        click_link "Resend invitation email"
        click_button "Resend invitation email"

        assert page.has_content?("Resent account invitation email")
        emails_received = all_emails.count { |email| email.subject == I18n.t("devise.mailer.invitation_instructions.subject") }
        assert_equal 2, emails_received
      end
    end

    should "grant the permissions selected" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor")
      application_two = create(:application)
      create(:supported_permission, application: application_two, name: "gds-admin")

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"

      within_fieldset application_one.name do
        uncheck "Has access to #{application_one.name}?"
        check "editor", allow_label_click: true
      end
      within_fieldset application_two.name do
        check "Has access to #{application_two.name}?"
        uncheck "gds-admin", allow_label_click: true
      end

      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert_not u.has_access_to? application_one
      assert_includes u.permissions_for(application_one), "editor"
      assert u.has_access_to? application_two
      assert_not_includes u.permissions_for(application_two), "gds-admin"
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor", default: true)
      application_two = create(:application)
      application_two.signin_permission.update!(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert u.has_access_to? application_two
      assert_equal %w[editor], u.permissions_for(application_one)
    end

    should "show an error message when attempting to create a user without an email" do
      visit new_user_invitation_path
      fill_in "Name", with: "Fred Bloggs"
      click_button "Create user and send email"

      assert_response_contains("Email can't be blank")
    end
  end

  context "as a superadmin" do
    setup do
      superadmin = create(:superadmin_user)
      visit root_path
      signin_with(superadmin)
    end

    should "present the role selector" do
      visit new_user_invitation_path
      assert has_select?("Role")
    end

    context "for roles that do not have mandatory 2SV" do
      should "create and notify the user" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred_admin@example.com"
          click_button "Create user and send email"

          assert_equal "fred_admin@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject

          assert has_field?("Mandate 2-step verification for this user")
          check "Mandate 2-step verification for this user"
          click_button "Update user"

          assert_not_nil User.find_by(
            email: "fred_admin@example.com",
            role: "normal",
            require_2sv: true,
          )
          assert_equal "fred_admin@example.com", last_email.to[0]
          assert_match "Make your Signon account more secure", last_email.subject
        end
      end
    end

    context "for user roles that have mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user for a superadmin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Superadmin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Superadmin.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
          assert User.where(email: "fred@example.com", role: Roles::Superadmin.name).last.require_2sv?
        end
      end

      should "create and notify the user for an admin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Admin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Admin.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
          assert User.where(email: "fred@example.com", role: Roles::Admin.name).last.require_2sv?
        end
      end
    end

    context "for user roles that have mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user for a superadmin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Superadmin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Superadmin.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
          assert User.where(email: "fred@example.com", role: Roles::Superadmin.name).last.require_2sv?
        end
      end

      should "create and notify the user for an admin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Admin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: Roles::Admin.name).last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match I18n.t("devise.mailer.invitation_instructions.subject"), last_email.subject
          assert User.where(email: "fred@example.com", role: Roles::Admin.name).last.require_2sv?
        end
      end
    end

    should "grant the permissions selected" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor")
      application_two = create(:application)
      create(:supported_permission, application: application_two, name: "gds-admin")

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"

      within_fieldset application_one.name do
        uncheck "Has access to #{application_one.name}?"
        check "editor"
      end
      within_fieldset application_two.name do
        check "Has access to #{application_two.name}?"
        uncheck "gds-admin"
      end

      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert_not u.has_access_to? application_one
      assert_includes u.permissions_for(application_one), "editor"
      assert u.has_access_to? application_two
      assert_not_includes u.permissions_for(application_two), "gds-admin"
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor", default: true)
      application_two = create(:application)
      application_two.signin_permission.update!(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      check "Mandate 2-step verification for this user"
      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert u.has_access_to? application_two
      assert_equal %w[editor], u.permissions_for(application_one)
    end
  end

  context "Notify service is using an allowlist or is in trial mode" do
    setup do
      admin = create(:admin_user)
      visit root_path
      signin_with(admin)
    end

    should "raise an error if email address is not in Notify team" do
      response = stub("response", code: 400, body: "Can't send to this recipient using a team-only API key")
      User.stubs(:invite!).raises(Notifications::Client::BadRequestError, response)

      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        assert_response_contains "Error: One or more recipients not in GOV.UK Notify team (code: 400)"
      end
    end
  end

  context "with JavaScript enabled" do
    setup do
      use_javascript_driver

      create(:organisation, name: "ABCDEF")
      create(:organisation, name: "GHIJKL")
      @organisation = create(:organisation, name: "MNOPQR")
      create(:organisation, name: "STUVWX")
      create(:organisation, name: "YZ1234")

      superadmin = create(:superadmin_user)
      visit root_path
      signin_with(superadmin)
    end

    should "be able to invite a user" do
      visit new_user_invitation_path
      fill_in "Name", with: "H from Steps"
      fill_in "Email", with: "h@from.steps"
      select "Superadmin", from: "Role"

      AutocompleteHelper.new.select_autocomplete_option(@organisation.name)

      click_button "Create user and send email"

      new_user = User.find_by(email: "h@from.steps", role: Roles::Superadmin.name)
      assert_not_nil new_user
      assert_equal new_user.organisation, @organisation
    end
  end
end
