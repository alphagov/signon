class Superadmin::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_filter :must_be_superadmin

  private
    def must_be_superadmin
      if ! current_user.has_role?("superadmin")
        flash[:alert] = "You must be a superadmin to do superadmin things."
        redirect_to root_path
      end
    end
end