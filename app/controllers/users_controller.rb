class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => :show
  doorkeeper_for :show
  before_filter :validate_token_matches_client_id, :only => :show

  # it's okay for current_user to modify own attributes
  skip_authorization_check

  def show
    relevant_permission.synced! if relevant_permission
    respond_to do |format|
      format.json do
        presenter = UserOAuthPresenter.new(current_resource_owner, application_making_request)
        render json: presenter.as_hash.to_json
      end
    end
  end

  def update
    if current_user.email == params[:user][:email].strip
      flash[:alert] = "Nothing to update."
      render :edit
    elsif current_user.update_attributes(email: params[:user][:email])
      EventLog.record_event(current_user, EventLog::EMAIL_CHANGE_INITIATIED, current_user)
      redirect_to root_path, notice: "An email has been sent to #{params[:user][:email]}. Follow the link in the email to update your address."
    else
      flash[:alert] = "Failed to change email."
      render :edit
    end
  end

  def update_passphrase
    params[:user] ||= {}
    password_params = params[:user].symbolize_keys.keep_if { |k, v| [:current_password, :password, :password_confirmation].include?(k) }
    if current_user.update_with_password(password_params)
      flash[:notice] = t(:updated, :scope => 'devise.passwords')
      sign_in(current_user, :bypass => true)
      redirect_to root_path
    else
      EventLog.record_event(current_user, EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE)
      render :edit
    end
  end

  def resend_email_change
    current_user.resend_confirmation_token
    if current_user.errors.empty?
      redirect_to root_path, notice: "An email has been sent to #{current_user.unconfirmed_email}. Follow the link in the email to update your address."
    else
      redirect_to edit_user_path(current_user), alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    current_user.unconfirmed_email = nil
    current_user.confirmation_token = nil
    current_user.save(validate: false)
    redirect_to edit_user_path(current_user)
  end

  private
    def relevant_permission
      current_resource_owner
          .permissions
          .where(application_id: application_making_request.id)
          .first
    end

    def application_making_request
      ::Doorkeeper::Application.find(doorkeeper_token.application_id)
    end

  def validate_token_matches_client_id
    # FIXME: Once gds-sso is updated everywhere, this should always validate
    # the client_id param.  It should 401 if no client_id is given.
    if params[:client_id].present?
      if params[:client_id] != doorkeeper_token.application.uid
        head :unauthorized
      end
    end
  end
end
