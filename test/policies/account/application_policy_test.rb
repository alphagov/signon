require "test_helper"
require "support/policy_helpers"

class Account::ApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  setup do
    @current_user = create(:user)
    @application = create(:application)
  end

  %i[show index view_permissions].each do |aliased_method|
    context "##{aliased_method}?" do
      setup { @args = [@current_user, @application, aliased_method] }

      context "when the current user is a GOV.UK admin" do
        should "be permitted" do
          @current_user.expects(:govuk_admin?).returns(true)

          assert permit?(*@args)
        end
      end

      context "when the current user is a publishing manager" do
        should "be permitted" do
          @current_user.expects(:govuk_admin?).returns(false)
          @current_user.expects(:publishing_manager?).returns(true)

          assert permit?(*@args)
        end
      end

      context "when the current user is neither a GOV.UK admin nor a publishing manager" do
        should "be forbidden" do
          @current_user.expects(:govuk_admin?).returns(false)
          @current_user.expects(:publishing_manager?).returns(false)

          assert forbid?(*@args)
        end
      end
    end
  end

  context "#grant_signin_permission?" do
    setup { @args = [@current_user, @application, :grant_signin_permission] }

    context "when the current user is a GOV.UK admin" do
      should "be permitted" do
        @current_user.expects(:govuk_admin?).returns(true)

        assert permit?(*@args)
      end
    end

    context "when the current user is not a GOV.UK admin" do
      should "be forbidden" do
        @current_user.expects(:govuk_admin?).returns(false)

        assert forbid?(*@args)
      end
    end
  end

  %i[remove_signin_permission edit_permissions].each do |aliased_method|
    context "##{aliased_method}?" do
      setup { @args = [@current_user, @application, aliased_method] }

      context "when the current user has access to the application" do
        setup { @current_user.expects(:has_access_to?).returns(true) }

        context "when the current user is a GOV.UK admin" do
          should "be permitted" do
            @current_user.expects(:govuk_admin?).returns(true)

            assert permit?(*@args)
          end
        end

        context "when the current user is a publishing manager" do
          setup do
            @current_user.expects(:govuk_admin?).returns(false)
            @current_user.expects(:publishing_manager?).returns(true)
          end

          context "when the application's signin permission is delegatable" do
            should "be permitted" do
              @application.signin_permission.update!(delegatable: true)

              assert permit?(*@args)
            end
          end

          context "when the application's signin permission is not delegatable" do
            should "be forbidden" do
              @application.signin_permission.update!(delegatable: false)

              assert forbid?(*@args)
            end
          end
        end

        context "when the current user is neither a GOV.UK admin nor a publishing manager" do
          should "be forbidden" do
            @current_user.expects(:govuk_admin?).returns(false)
            @current_user.expects(:publishing_manager?).returns(false)

            assert forbid?(*@args)
          end
        end
      end

      context "when the current user does not have access to the application" do
        should "be forbidden" do
          @current_user.expects(:has_access_to?).returns(false)

          assert forbid?(*@args)
        end
      end
    end
  end
end
