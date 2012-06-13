class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order("created_at desc")
  end
end
