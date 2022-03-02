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

private

  def create_application(name:, redirect_uri:, description:, home_uri:, permissions:)
    Doorkeeper::Application.transaction do
      application = Doorkeeper::Application.create!(
        name: name,
        redirect_uri: redirect_uri,
        description: description,
        home_uri: home_uri,
      )
      permissions.each do |permission|
        SupportedPermission.create!(
          application_id: application.id,
          name: permission,
        )
      end
      application
    end
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
    {
      id: application.id,
      oauth_id: application.uid,
      oauth_secret: application.secret,
      permissions: application.reload.supported_permission_strings - DEFAULT_PERMISSIONS,
    }
  end
end
