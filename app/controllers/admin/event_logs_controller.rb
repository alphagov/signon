class Admin::EventLogsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  respond_to :html

  def index
    @user = User.find_by_id(params["user_id"])
    @logs = EventLog.for(@user)
  end
end
