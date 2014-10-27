class Admin::EventLogsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def index
    @user = User.find_by_id(params["user_id"])
    @logs = EventLog.for(@user)
    @logs = @logs.page(params[:page]).per(100)
  end
end
