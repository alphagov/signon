require "test_helper"

class BulkUpdate::BulkUpdateUserControllerTest < ActionController::TestCase
  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    context "GET index" do
      should "return not authorised response" do
        get :index

        assert_not_authorised
      end
    end
  end

  context "as superadmin" do
    setup do
      @superadmin = create(:superadmin_user)
      sign_in @superadmin
    end

    context "GET index" do
      should "render form" do
        get :index

        assert_select "form" do
          assert_select "input[type='file'][name='csv_file']"
        end
      end
    end

    context "PATCH update" do
      should "reject a CSV with users that do not exist" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email
          #{user.email},new-1@gov.uk
          old-1@gov.uk,new-1@gov.uk
          old-2@gov.uk,new-2@gov.uk
        CSV

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }

        assert_select "p.gem-c-error-alert__message", "Email addresses in file that do not exist: old-1@gov.uk, old-2@gov.uk"
      end

      should "does not update valid users if the CSV contains user that does not exist" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email
          #{user.email},new-1@gov.uk
          old-1@gov.uk,new-1@gov.uk
          old-2@gov.uk,new-2@gov.uk
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload } do
          post :create, params: { csv_file: file }
        end
      end

      should "does not update valid users if the CSV contains a blank old email" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email
          #{user.email},new-1@gov.uk
          ,new-1@gov.uk
          old-2@gov.uk,new-2@gov.uk
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload } do
          post :create, params: { csv_file: file }
        end
      end

      should "does not update valid users if the CSV contains the same email twice" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email
          #{user.email},new-1@gov.uk
          #{user.email},new-2@gov.uk
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload } do
          post :create, params: { csv_file: file }

          assert_select "p.gem-c-error-alert__message", "Email addresses in file more than once: #{user.email}"
        end
      end

      should "delegate updates to UserUpdate with correct audit trail arguments" do
        actor_ip_address = "1.1.1.1"
        @controller.stubs(:user_ip_address).returns(actor_ip_address)

        user = create(:user)
        organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user.email},new@gov.uk,#{organisation.slug}
        CSV

        user_update = mock

        UserUpdate.expects(:new).with(
          user,
          {
            email: "new@gov.uk",
            organisation: organisation,
          },
          @superadmin,
          actor_ip_address,
        ).returns(user_update)

        user_update.expects(:call)

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }
      end

      should "does not update any users when UserUpdate fails for one user" do
        actor_ip_address = "1.1.1.1"
        @controller.stubs(:user_ip_address).returns(actor_ip_address)

        user_1 = create(:user)
        user_2 = create(:user)
        organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user_1.email},new-1@gov.uk,#{organisation.slug}
          #{user_2.email},new-2@gov.uk,#{organisation.slug}
        CSV

        user_update_success = mock

        UserUpdate.expects(:new).with(
          user_1,
          {
            email: "new-1@gov.uk",
            organisation: organisation,
          },
          @superadmin,
          actor_ip_address,
        ).returns(user_update_success)

        user_update_success.expects(:call).returns(true)

        user_update_fail = mock

        UserUpdate.expects(:new).with(
          user_2,
          {
            email: "new-2@gov.uk",
            organisation: organisation,
          },
          @superadmin,
          actor_ip_address,
        ).returns(user_update_fail)

        user_update_fail.expects(:call).returns(nil)

        file = csv_to_file(csv_content)

        assert_no_changes -> { user_1.reload } do
          post :create, params: { csv_file: file }
          assert_select "p.gem-c-error-alert__message", "Failed to update: #{user_2.email}"
        end
      end

      should "update email address if the CSV contains valid users and new emails" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email
          #{user.email},new-1@gov.uk
        CSV

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }

        assert_equal "new-1@gov.uk", user.reload.email
      end

      should "update user organisation if the CSV contains valid users and valid new organisation" do
        user = create(:user)
        new_organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New organisation
          #{user.email},#{new_organisation.slug}
        CSV

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }

        assert_equal new_organisation, user.reload.organisation
      end

      should "update user email and organisation if the CSV contains valid users, new email and valid new organisation" do
        user_1 = create(:user)
        user_2 = create(:user)
        new_organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user_1.email},"new-1@gov.uk",#{new_organisation.slug}
          #{user_2.email},"new-2@gov.uk",#{new_organisation.slug}
        CSV

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }

        assert_equal "new-1@gov.uk", user_1.reload.email
        assert_equal new_organisation, user_1.reload.organisation
        assert_equal "new-2@gov.uk", user_2.reload.email
        assert_equal new_organisation, user_2.reload.organisation
      end

      should "show a count of the users updated if the CSV contains valid data" do
        user_1 = create(:user)
        user_2 = create(:user)
        new_organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user_1.email},"new-1@gov.uk",#{new_organisation.slug}
          #{user_2.email},"new-2@gov.uk",#{new_organisation.slug}
        CSV

        file = csv_to_file(csv_content)

        post :create, params: { csv_file: file }

        assert_select "div.govuk-notification-banner__content h3", "Users updated"
        assert_select "div.govuk-notification-banner__content", /2 users have been updated/
      end

      should "does not update valid users if the CSV contains a new organisation that does not exist" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New organisation
          #{user.email},not-an-organisation
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload } do
          post :create, params: { csv_file: file }
        end
      end

      should "does not update email if the CSV contains a blank new email" do
        user = create(:user)
        new_organisation = create(:organisation)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user.email},,#{new_organisation.slug}
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload.email } do
          post :create, params: { csv_file: file }
        end
      end

      should "does not update organisation if the CSV contains a blank new organisation" do
        user = create(:user)

        csv_content = <<~CSV
          Old email,New email,New organisation
          #{user.email},new-1@gov.uk,
        CSV

        file = csv_to_file(csv_content)

        assert_no_changes -> { user.reload.organisation } do
          post :create, params: { csv_file: file }
        end
      end

      should "show an error if the CSV is not present" do
        post :create, params: { csv_file: nil }

        assert_select "p.gem-c-error-alert__message", "A CSV file is required"
      end
    end
  end

  def csv_to_file(file_content)
    Rack::Test::UploadedFile.new(
      StringIO.new(file_content),
      "text/csv",
      original_filename: "users.csv",
    )
  end
end
