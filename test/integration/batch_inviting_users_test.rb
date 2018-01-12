require 'test_helper'

class BatchInvitingUsersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @cabinet_office = create(:organisation, slug: 'cabinet-office', name: 'Cabinet Office')
    @department_of_hats = create(:organisation, slug: 'department-of-hats', name: 'Department of Hats')
    @application = create(:application)
  end

  context 'for superadmin users' do
    setup do
      @user = create(:superadmin_user)
    end

    should "allow creating users whose details are specified in a CSV file, assigning them all to one org" do
      perform_batch_invite_with_user(@user, @application, organisation: @cabinet_office)
      assert_user_created_and_invited('fred@example.com', @application, organisation: @cabinet_office)
    end

    should "allow creating users with org details specified in a CSV file, overriding the org selected in the form" do
      perform_batch_invite_with_user(@user, @application, fixture_file: 'users_with_orgs.csv', user_count: 3, organisation: @cabinet_office)
      assert_user_created_and_invited('fred@example.com', @application, organisation: @department_of_hats)
      assert_user_created_and_invited('lara@example.com', @application, organisation: @cabinet_office)
      assert_user_not_created('emma@example.com')
    end
  end

  context 'for admin users' do
    setup do
      @user = create(:admin_user)
    end

    should "allow creating users whose details are specified in a CSV file, assigning them all to one org" do
      perform_batch_invite_with_user(@user, @application, organisation: @cabinet_office)
      assert_user_created_and_invited('fred@example.com', @application, organisation: @cabinet_office)
    end

    should "ignore org details specified in a CSV file, creating all the users assigned to one org" do
      perform_batch_invite_with_user(@user, @application, fixture_file: 'users_with_orgs.csv', user_count: 3, organisation: @cabinet_office)
      assert_user_created_and_invited('fred@example.com', @application, organisation: @cabinet_office)
      assert_user_created_and_invited('lara@example.com', @application, organisation: @cabinet_office)
      assert_user_created_and_invited('emma@example.com', @application, organisation: @cabinet_office)
    end
  end

  context 'for organisation admins' do
    setup do
      @user = create(:organisation_admin)
      @user.grant_application_permission(@application, ['signin'])
    end

    should "not allow batch inviting users" do
      visit root_path
      signin_with(@user)

      visit new_batch_invitation_path
      assert_equal root_path, current_path
    end
  end

  context 'for super organisation admins' do
    setup do
      @user = create(:super_org_admin)
      @user.grant_application_permission(@application, ['signin'])
    end

    should "not allow batch inviting users" do
      visit root_path
      signin_with(@user)

      visit new_batch_invitation_path
      assert_equal root_path, current_path
    end
  end

  should "ensure that batch invited users get default permissions even when not checked in UI" do
    create(:supported_permission, application: @application, name: 'reader', default: true)
    support_app = create(:application, name: 'support', with_supported_permissions: ['signin'])
    support_app.signin_permission.update_attributes(default: true)
    user = create(:admin_user)

    visit root_path
    signin_with(user)

    perform_enqueued_jobs do
      visit new_batch_invitation_path
      path = File.join(::Rails.root, "test", "fixtures", "users.csv")
      attach_file("Choose a CSV file of users with names and email addresses", path)
      uncheck "Has access to #{support_app.name}?"
      check "Has access to #{@application.name}?"
      unselect 'reader', from: "Permissions for #{@application.name}"
      click_button "Create users and send emails"

      invited_user = User.find_by_email("fred@example.com")
      assert invited_user.has_access_to?(support_app)
      assert invited_user.permissions_for(@application).include? 'reader'
    end
  end

  def perform_batch_invite_with_user(user, application, fixture_file: 'users.csv', user_count: 1, organisation:)
    perform_enqueued_jobs do
      visit root_path
      signin_with(user)

      visit new_batch_invitation_path
      path = File.join(::Rails.root, "test", "fixtures", fixture_file)
      attach_file("Choose a CSV file of users with names and email addresses", path)
      check "Has access to #{application.name}?"
      if organisation
        select organisation.name, from: 'Organisation'
      end

      click_button "Create users and send emails"

      assert_response_contains("Creating a batch of users")
      assert_response_contains("#{user_count} users processed")
    end
  end

  def assert_user_created_and_invited(email, application, organisation: nil)
    invited_user = User.find_by_email(email)
    assert_not_nil invited_user
    assert invited_user.has_access_to?(application)
    if organisation
      assert_equal organisation.name, invited_user.organisation.name
    end
    invite_email = last_email_for(email)
    assert_not_nil invite_email
    assert_equal "noreply-signon-development@digital.cabinet-office.gov.uk", invite_email.from[0]
    assert_equal nil, invite_email.reply_to[0]

    assert_match 'Please confirm your account', invite_email.subject
  end

  def assert_user_not_created(email)
    invited_user = User.find_by_email(email)
    assert_nil invited_user

    invite_email = last_email_for(email)
    assert_nil invite_email
  end
end
