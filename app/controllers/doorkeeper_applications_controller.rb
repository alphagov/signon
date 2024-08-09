class DoorkeeperApplicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_application, except: :index

  respond_to :html

  def index
    authorize Doorkeeper::Application
    @applications = Doorkeeper::Application.all
  end

  def edit; end

  def update
    if @application.update(doorkeeper_application_params)
      redirect_to doorkeeper_applications_path, notice: "Successfully updated #{@application.name}"
    else
      respond_with @application
    end
  end

  def users_with_access
    query = policy_scope(User).with_access_to_application(@application)
    @users = query.page(params[:page]).per(100)
  end

  def access_logs
    relation = @application.event_logs
      .includes(:user)
      .where(event_id: 47)
      .order(created_at: :desc)

    unless params[:include_smokey_users] == "true"
      smokey_uids = User.where("name LIKE 'Smokey%'").pluck(:uid)
      relation = relation.where.not(uid: smokey_uids)
    end

    if params[:month].present?
      relation = relation.where("DATE_FORMAT(created_at, '%Y-%m')=?", params[:month])
    end

    @logs = relation
      .page(params[:page])
      .per(100)
  end

private

  def load_and_authorize_application
    @application = Doorkeeper::Application.unscoped.find(params[:id])
    authorize @application
  end

  def doorkeeper_application_params
    # Since our Pundit policies ensure that only a superadmin can access this
    # controller, we can whitelist all attributes the edit form can modify
    params.require(:doorkeeper_application).permit(
      :name,
      :description,
      :uid,
      :secret,
      :redirect_uri,
      :retired,
      :home_uri,
      :supports_push_updates,
      :api_only,
      :include_smokey_users,
      :month,
    )
  end
end
