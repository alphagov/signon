module ManagingTwoSvHelpers
  include ActiveJob::TestHelper

  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  def assert_user_access_log_contains_messages(user, messages)
    visit edit_user_path(user)
    click_link "Account access log"

    messages.each { |message| assert page.has_text? message }
  end

  def mandate_2sv_for_exempted_user
    check "Mandate 2-step verification for this user (this will remove their exemption)"
    click_button "Update User"
  end

  def assert_admin_can_send_2fa_email(admin, user)
    sign_in_as_and_edit_user(admin, user)

    assert page.has_text? "2-step verification not set up"

    perform_enqueued_jobs do
      check "Mandate 2-step verification for this user"
      click_button "Update User"

      assert last_email
      assert_equal "Make your Signon account more secure", last_email.subject
    end

    assert user.reload.require_2sv
  end

  def assert_admin_can_remove_2sv_requirement_without_notifying_user(admin, user)
    sign_in_as_and_edit_user(admin, user)

    perform_enqueued_jobs do
      uncheck "Mandate 2-step verification for this user"
      click_button "Update User"

      assert_not last_email
    end

    assert_not user.reload.require_2sv
  end
end
