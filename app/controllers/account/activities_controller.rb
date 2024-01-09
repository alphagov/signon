class Account::ActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorise_user

  def show
    @logs = current_user.event_logs.page(params[:page]).per(100)
  end

private

  def authorise_user
    authorize %i[account activities]
  end
end
