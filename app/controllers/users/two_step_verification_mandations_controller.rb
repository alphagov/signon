class Users::TwoStepVerificationMandationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user

  def edit; end

  def update
    user_params = { require_2sv: true }
    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to edit_user_path(@user), notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize(@user, :mandate_2sv?)
  end
end
