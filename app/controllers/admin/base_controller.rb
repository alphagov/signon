class Admin::BaseController < ApplicationController
  before_filter :must_be_admin

  private
    def must_be_admin
      if ! current_user.is_admin?
        flash[:alert] = "You must be an admin to do admin things."
        redirect_to root_path
      end
    end
end