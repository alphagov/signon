class Admin::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_filter :must_be_admin

  private
    def must_be_admin
      if ! current_user.role? :admin
        flash[:alert] = "You must be an admin to do admin things."
        redirect_to root_path
      end
    end
end