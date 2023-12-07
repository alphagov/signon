class Users::InvitationResendsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user
  before_action :redirect_if_invitation_already_accepted

  def edit; end

  def update
    @user.invite!(current_user)
    EventLog.record_account_invitation(@user)
    flash[:notice] = "Resent account invitation email to #{@user.email}"
    redirect_to edit_user_path(@user)
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize(@user, :resend_invitation?)
  end

  def redirect_if_invitation_already_accepted
    unless @user.invited_but_not_yet_accepted?
      flash[:notice] = "Invitation for #{@user.email} has already been accepted"
      redirect_to edit_user_path(@user)
    end
  end
end
