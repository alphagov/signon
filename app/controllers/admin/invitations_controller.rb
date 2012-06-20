# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class Admin::InvitationsController < Devise::InvitationsController
  before_filter :authenticate_user!
  before_filter :must_be_admin, only: [:new, :create]

  def create
    self.resource = resource_class.invite!(params[resource_name], current_inviter)

    self.resource.update_attribute(:is_admin, params[:user][:is_admin])

    if resource.errors.empty?
      set_flash_message :notice, :send_instructions, :email => self.resource.email
      respond_with resource, :location => after_invite_path_for(resource)
    else
      respond_with_navigational(resource) { render :new }
    end
  end

  def resend
    user = User.find(params[:id])
    user.invite!
    flash[:notice] = "Resent account signup email to #{user.email}"
    redirect_to admin_users_path
  end

  private
    def must_be_admin
      if ! current_user.is_admin?
        flash[:alert] = "You must be an admin to do admin things."
        redirect_to root_path
      end
    end

    def after_invite_path_for(resource)
      admin_users_path
    end
end
