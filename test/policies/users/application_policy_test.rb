require "test_helper"
require "support/policy_helpers"

class Users::ApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  include PunditHelpers

  setup do
    @current_user = create(:user)
    @user = create(:user)
    @application = create(:application)
  end

  %i[grant_signin_permission remove_signin_permission].each do |aliased_method|
    context "##{aliased_method}?" do
      setup do
        @args = [
          @current_user,
          { application: @application, user: @user },
          aliased_method,
        ]
      end

      context "when the current user can edit the given user" do
        setup { stub_policy @current_user, @user, edit?: true }

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

          context "when the current user has access to the application and the application's signin permission is delegatable" do
            should "be permitted" do
              @current_user.expects(:has_access_to?).with(@application).returns(true)
              @application.signin_permission.update!(delegatable: true)

              assert permit?(*@args)
            end
          end

          context "when the application's signin permission is delegatable but the user doesn't have access to the application" do
            should "be forbidden" do
              @current_user.expects(:has_access_to?).with(@application).returns(false)
              @application.signin_permission.update!(delegatable: true)

              assert forbid?(*@args)
            end
          end

          context "when the current user has access to the application but the application's signion permission is not delegatable" do
            should "be forbidden" do
              @current_user.expects(:has_access_to?).with(@application).returns(true)
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

      context "when the current user cannot edit the given user" do
        should "be forbidden" do
          stub_policy @current_user, @user, edit?: false

          assert forbid?(*@args)
        end
      end
    end
  end

  context "#view_permissions?" do
    setup do
      @args = [
        @current_user,
        { application: @application, user: @user },
        :view_permissions,
      ]
    end

    context "when the current user can edit the given user" do
      setup { stub_policy @current_user, @user, edit?: true }
      should("be permitted") { assert permit?(*@args) }
    end

    context "when the current user cannot edit the given user" do
      setup { stub_policy @current_user, @user, edit?: false }
      should("be forbidden") { assert forbid?(*@args) }
    end
  end

  context "#edit_permissions" do
    setup do
      @args = [
        @current_user,
        { application: @application, user: @user },
        :edit_permissions,
      ]
    end

    context "when the current user can edit the given user" do
      setup { stub_policy @current_user, @user, edit?: true }

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

        context "when the current user has access to the application and the application has delegatable non-signin permissions" do
          should "be permitted" do
            @current_user.expects(:has_access_to?).with(@application).returns(true)
            @application.stubs(:has_delegatable_non_signin_permissions?).returns(true)

            assert permit?(*@args)
          end
        end

        context "when the application has delegatable non-signin permissions but the user doesn't have access to the application" do
          should "be forbidden" do
            @current_user.expects(:has_access_to?).with(@application).returns(false)
            @application.stubs(:has_delegatable_non_signin_permissions?).returns(true)

            assert forbid?(*@args)
          end
        end

        context "when the current user has access to the application but the application does not have delegatable non-signin permissions" do
          should "be forbidden" do
            @current_user.expects(:has_access_to?).with(@application).returns(true)
            @application.stubs(:has_delegatable_non_signin_permissions?).returns(false)

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

    context "when the current user cannot edit the given user" do
      should "be forbidden" do
        stub_policy @current_user, @user, edit?: false

        assert forbid?(*@args)
      end
    end
  end
end
