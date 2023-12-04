module ManagingTwoSvHelpers
  include ActiveJob::TestHelper

  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  def exemption_message(initiator, reason, expiry_date)
    "Exempted from 2-step verification by #{initiator.name} for reason: #{reason} expiring on date: #{expiry_date}"
  end

  def assert_user_access_log_contains_messages(user, messages)
    visit edit_user_path(user)
    click_link "View account access log"

    messages.each { |message| assert page.has_text? message }
  end

  def mandate_2sv_for_exempted_user
    click_link "Mandate 2-step verification for this user (this will remove their exemption)"
    click_button "Turn on 2-step verification"
  end

  def admin_can_send_2sv_email(admin, user)
    sign_in_as_and_edit_user(admin, user)

    assert page.has_text?(/2-step verification\s+Not set up/)

    perform_enqueued_jobs do
      click_link "Mandate 2-step verification for this user"
      click_button "Turn on 2-step verification"

      assert last_email
      assert_equal "Make your Signon account more secure", last_email.subject
    end

    assert user.reload.require_2sv
  end

  def admin_can_reset_2sv_on_user(logged_in_as, user_to_be_reset)
    visit edit_user_path(user_to_be_reset)
    signin_with(logged_in_as)

    perform_enqueued_jobs do
      assert page.has_text?(/2-step verification\s+Enabled/)

      click_link "Reset 2-step verification"
      click_button "Reset 2-step verification"

      assert_response_contains "Reset 2-step verification for #{user_to_be_reset.email}"

      assert last_email
      assert_equal "2-step verification has been reset", last_email.subject
    end
  end

  def user_cannot_reset_2sv(logged_in_as, user_to_be_reset)
    visit edit_user_path(user_to_be_reset)
    signin_with(logged_in_as)

    assert page.has_no_link? "Reset 2-step verification"
  end

  def user_can_be_exempted_from_2sv(signed_in_as, user_being_exempted, reason, expiry_date)
    sign_in_as_and_edit_user(signed_in_as, user_being_exempted)
    click_link("Exempt user from 2-step verification")
    fill_in_exemption_form(reason, expiry_date)

    assert_user_has_been_exempted_from_2sv(user_being_exempted, reason, expiry_date)
  end

  def fill_in_exemption_form(reason, expiry_date)
    fill_in "Reason for 2-step verification exemption", with: reason
    fill_in_expiry_date(expiry_date)
    click_button "Save"
  end

  def fill_in_expiry_date(date)
    fill_in "Day", with: date.day
    fill_in "Month", with: date.month
    fill_in "Year", with: date.year
  end

  def assert_user_has_been_exempted_from_2sv(user, reason, expiry_date)
    user.reload

    assert_not user.require_2sv?
    assert_equal reason, user.reason_for_2sv_exemption
    assert_equal expiry_date, user.expiry_date_for_2sv_exemption

    assert page.has_text?(/2-step verification\s+Exempt/)
  end

  def assert_user_has_not_been_exempted_from_2sv(user)
    currently_requires_2sv = user.require_2sv

    user.reload
    assert_equal currently_requires_2sv, user.require_2sv
    assert_nil user.reason_for_2sv_exemption
    assert_nil user.expiry_date_for_2sv_exemption
  end
end
