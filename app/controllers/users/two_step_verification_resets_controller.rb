class Users::TwoStepVerificationResetsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user
  before_action :redirect_to_account_page_if_acting_on_own_user, only: %i[edit]

  def edit; end

  def update
    @user.reset_2sv!
    UserMailer.two_step_reset(@user).deliver_later

    redirect_to edit_user_path(@user), notice: "Reset 2-step verification for #{@user.email}"
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize(@user, :reset_2sv?)
  end

  def redirect_to_account_page_if_acting_on_own_user
    redirect_to two_step_verification_path if current_user == @user
  end
end
