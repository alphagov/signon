class Api::V1::AuthorisationsController < Api::V1::ApiController
  before_action :validate_create_params, only: %w[create]
  before_action :validate_application, only: %w[create]
  before_action :validate_test_params, only: %w[test]
  before_action :api_user

  def create
    authorisation = api_user.authorisations.build(
      expires_in: ApiUser::AUTOROTATABLE_TOKEN_LIFE,
      application_id: params.fetch(:application_id),
    )
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
        application_id: params.require(:application_id),
        token: params.require(:token),
      )

    render json: { application_name: authorisation.application.name }
  end

private

  def api_user
    @api_user ||= ApiUser.find(params.require(:id))
  end

  def validate_application
    # Doorkeeper doesn't validate application_ids, so we must
    unless Doorkeeper::Application.exists?(params.fetch(:application_id))
      raise ActiveRecord::RecordNotFound
    end
  end

  def grant_app_permissions!(authorisation, permissions)
    all_permissions = %w[signin] + permissions
    api_user.grant_application_permissions(authorisation.application, all_permissions)
  end

  def validate_create_params
    assert_no_missing_params(%i[application_id])
  end

  def validate_test_params
    assert_no_missing_params(%i[application_id token])
  end
end
