require "test_helper"

class UserParameterSanitiserTest < ActiveSupport::TestCase
  context "with Plain Old Ruby Hash for params" do
    setup do
      permitted_params_by_role = { normal: %i[name email] }
      @user_params = { name: "Anne", email: "anne@anne.com" }

      @sanitised_params = UserParameterSanitiser.new(
        user_params: @user_params,
        current_user_role: :normal,
        permitted_params_by_role: permitted_params_by_role,
      ).sanitise
    end

    should "return permitted params object" do
      assert_instance_of ActionController::Parameters, @sanitised_params
      assert @sanitised_params.permitted?
    end

    should "permit the permitted params" do
      assert_equal @user_params[:name], @sanitised_params[:name]
      assert_equal @user_params[:email], @sanitised_params[:email]
    end
  end

  context "when unpermitted params are supplied" do
    setup do
      permitted_params_by_role = {
        normal: %i[name email],
        superadmin: %i[name email birthday],
      }
      user_params = { name: "Mary", birthday: "today!" }

      @sanitised_params = UserParameterSanitiser.new(
        user_params: user_params,
        current_user_role: :normal,
        permitted_params_by_role: permitted_params_by_role,
      ).sanitise
    end

    should "remove unpermitted params" do
      assert !@sanitised_params.has_key?(:birthday)
    end
  end

  context "with complex parameters" do
    setup do
      permitted_params_by_role = {
        superadmin: [
          :name,
          { some_ids: [] },
        ],
      }
      @some_ids = [1, 2, 3]
      user_params = { name: "Mary", some_ids: @some_ids }

      @sanitised_params = UserParameterSanitiser.new(
        user_params: user_params,
        current_user_role: :superadmin,
        permitted_params_by_role: permitted_params_by_role,
      ).sanitise
    end

    should "allow any scalar values in the array" do
      assert_equal @some_ids, @sanitised_params[:some_ids]
    end
  end
end
