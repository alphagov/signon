class TwoStepVerificationExemptionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def edit
    @exemption = TwoStepVerificationExemption.from_user(@user)
  end

  def update
    @exemption = TwoStepVerificationExemption.from_params(exemption_params)
    if @exemption.valid?
      @user.exempt_from_2sv(@exemption.reason, current_user, @exemption.expiry_date)
      flash[:notice] = "User exempted from 2-step verification"
      redirect_to edit_user_path(@user)
    else
      render "edit"
    end
  end

private

  def exemption_params
    params.require(:exemption).permit(:reason, expiry_date: %i[day month year])
  end

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :exempt_from_two_step_verification?
  end
end
