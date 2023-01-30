class TwoStepVerificationExemptionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user

  def update
    @user.exempt_from_2sv(params[:user][:reason_for_2sv_exemption])

    redirect_to @user.api_user? ? edit_api_user_path(@user) : edit_user_path(@user)
  end

private

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :exempt_from_two_step_verification?
  end
end
