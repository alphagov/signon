class TwoStepVerificationExemptionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def edit; end

  def update
    if params[:user][:reason_for_2sv_exemption].empty?
      flash[:alert] = "Reason for exemption must be provided"

      redirect_to edit_two_step_verification_exemption_path(@user)
    else
      @user.exempt_from_2sv(params[:user][:reason_for_2sv_exemption])

      flash[:notice] = "User exempted from 2SV"

      redirect_to edit_user_path(@user)
    end
  end

private

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :exempt_from_two_step_verification?
  end
end
