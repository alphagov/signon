class Superuser::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_filter :must_be_superuser

  private
    def must_be_superuser
      if ! current_user.has_role?("superuser")
        flash[:alert] = "You must be a superuser to do superuser things."
        redirect_to root_path
      end
    end
end