class TwoStepVerificationExemptionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def edit; end

  def update
    if params[:user][:reason_for_2sv_exemption].empty?
      flash[:alert] = "Reason for exemption must be provided"

      redirect_to edit_two_step_verification_exemption_path(@user)
    else
      if params[:user]["expiry_date_for_2sv_exemption(1i)"]
        expiry_date = parse_date_from_user_params(params[:user])
      end
      @user.exempt_from_2sv(params[:user][:reason_for_2sv_exemption], current_user, expiry_date)

      flash[:notice] = "User exempted from 2SV"

      redirect_to edit_user_path(@user)
    end
  end

private

  def parse_date_from_user_params(user_params)
    date_part_params = ["expiry_date_for_2sv_exemption(1i)", "expiry_date_for_2sv_exemption(2i)", "expiry_date_for_2sv_exemption(3i)"]
    date_string = date_part_params.map { |param_name| user_params[param_name] }.join("/")
    Date.parse(date_string)
  end

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :exempt_from_two_step_verification?
  end
end
