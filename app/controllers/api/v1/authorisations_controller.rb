class Api::V1::AuthorisationsController < ApplicationController
  include AdminApiHelper

  before_action :authenticate
  before_action :validate_create_params, only: %w[create]
  before_action :validate_test_params, only: %w[test]
  before_action :api_user

  skip_after_action :verify_authorized
  protect_from_forgery with: :null_session

  rescue_from ActionController::ParameterMissing, with: :missing_params_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_error

  respond_to :json

  def create
    authorisation = api_user.authorisations.build(expires_in: ApiUser::AUTOROTATABLE_TOKEN_LIFE)
    authorisation.application_id = application.id
    ActiveRecord::Base.transaction do
      authorisation.save!
      grant_app_permissions!(authorisation, params.fetch(:permissions, []))
    end
    EventLog.record_event(
      api_user,
      EventLog::ACCESS_TOKEN_GENERATED,
      initiator: api_user,
      application: authorisation.application,
      ip_address: request.remote_ip,
    )
    render json: { application_name: authorisation.application.name, token: authorisation.token }
  end

  def test
    authorisation = api_user.authorisations
      .find_by!(
        application: application,
        token: params.require(:token),
      )

    render json: { application_name: authorisation.application.name }
  end

private

  def api_user
    @api_user ||= begin
      ApiUser.find_by!(email: params.require(:api_user_email))
    end
  end

  def application
    @application ||= Doorkeeper::Application.find_by!(name: params.require(:application_name))
  end

  def grant_app_permissions!(authorisation, permissions)
    all_permissions = %w[signin] + permissions
    @api_user.grant_application_permissions(authorisation.application, all_permissions)
  end

  def validate_create_params
    assert_no_missing_params(%i[application_name api_user_email])
  end

  def validate_test_params
    assert_no_missing_params(%i[application_name api_user_email token])
  end
end
