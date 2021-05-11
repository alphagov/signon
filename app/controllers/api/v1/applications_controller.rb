class Api::V1::ApplicationsController < ApplicationController
  include AdminApiHelper

  before_action :authenticate
  before_action :validate_params

  skip_after_action :verify_authorized
  protect_from_forgery with: :null_session

  rescue_from ActionController::ParameterMissing, with: :missing_params_error
  rescue_from ActiveRecord::RecordInvalid, with: :not_valid_error
  rescue_from ActiveRecord::RecordNotUnique, with: :already_exists_error

  respond_to :json

  def create
    application = create_application(
      name: params.fetch(:name),
      redirect_uri: params.fetch(:redirect_uri),
      description: params.fetch(:description),
      home_uri: params.fetch(:home_uri),
      permissions: params.fetch(:permissions, []),
    )
    render json: { oauth_id: application.uid, oauth_secret: application.secret }
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

  def validate_params
    assert_no_missing_params(%i[
      name description redirect_uri home_uri permissions
    ])
  end
end
