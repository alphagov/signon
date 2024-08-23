require "test_helper"

class UpdatingPermissionsForAppsWithManyPermissionsTest < ActionDispatch::IntegrationTest
  # Also see: Account::UpdatingPermissionsTest, Users::UpdatingPermissionsTest

  context "with apps that have more than eight permissions" do
    context "with JavaScript disabled" do
      should "be able to grant permissions" do
        skip
      end

      context "when the grantee already has some but not all permissions" do
        should "display the new and current permissions forms" do
          skip
        end
      end

      context "when the grantee has all permissions" do
        should "only display the current permissions form" do
          skip
        end
      end

      context "when the grantee has no permissions" do
        should "only display the new permissions form" do
          skip
        end
      end
    end

    context "with JavaScript enabled" do
      should "be able to grant permissions" do
        skip
      end

      should "grant permissions then redirect back to the form when clicking 'Add'" do
        skip
      end

      should "reset the value of the select element when it no longer matches what's shown in the autocomplete input" do
        skip
      end

      should "clear the value of the select and autocomplete elements when clicking the clear button" do
        skip
      end

      should "clear the value of the select and autocomplete elements when hitting space on the clear button" do
        skip
      end

      should "clear the value of the select and autocomplete elements when hitting enter on the clear button" do
        skip
      end
    end
  end
end
