class Api::V1::ApplicationsController < Api::V1::ApiController
  before_action :validate_create_params, only: %w[create]
  before_action :validate_show_params, only: %w[show]

  DEFAULT_PERMISSIONS = %w[signin user_update_permission].freeze

  def create
    application = create_application(
      name: params.fetch(:name),
      redirect_uri: params.fetch(:redirect_uri),
      description: params.fetch(:description),
      home_uri: params.fetch(:home_uri),
      permissions: params.fetch(:permissions, []),
    )
    render json: generate_response(application.reload)
  end

  def show
    application = Doorkeeper::Application.find_by!(name: params.fetch(:name))
    render json: generate_response(application)
  end

  def update
    application = update_application(
      Doorkeeper::Application.find(params.fetch(:id)),
      params.permit(:name, :description, permissions: []),
    )
    render json: generate_response(application)
  end

private

  def create_application(name:, redirect_uri:, description:, home_uri:, permissions:)
    Doorkeeper::Application.transaction do
      application = Doorkeeper::Application.create!(
        name: name,
        redirect_uri: redirect_uri,
        description: description,
        home_uri: home_uri,
      )
      create_permissions(application, permissions)
      application
    end
  end

  def update_application(application, fields)
    Doorkeeper::Application.transaction do
      live_permissions = application.supported_permission_strings
      desired_permissions = fields.fetch(:permissions, []) | DEFAULT_PERMISSIONS
      create_permissions(application, desired_permissions - live_permissions)
      delete_permissions(application, live_permissions - desired_permissions)
      application.update!(fields.slice(:name, :description))
      application
    end
  end

  def create_permissions(application, permissions)
    permissions.each do |permission|
      SupportedPermission.where(
        application_id: application.id,
        name: permission,
      ).first_or_create
    end
  end

  def delete_permissions(application, permissions)
    SupportedPermission.where(
      application_id: application.id,
      name: permissions,
    ).destroy_all
  end

  def validate_create_params
    assert_no_missing_params(%i[
      name description redirect_uri home_uri
    ])
  end

  def validate_show_params
    assert_no_missing_params(%i[name])
  end

  def generate_response(application)
    { application: {
      id: application.id.to_s,
      name: application.name,
      oauth_id: application.uid,
      oauth_secret: application.secret,
    } }
  end
end
