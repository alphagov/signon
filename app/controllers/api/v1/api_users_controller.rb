class Api::V1::ApiUsersController < Api::V1::ApiController
  before_action :validate_create_params, only: %w[create]
  before_action :validate_show_params, only: %w[show]

  def create
    api_user = create_api_user(name: params.fetch(:name), email: params.fetch(:email))
    render json: { id: api_user.id }
  end

  def show
    api_user = ApiUser.find_by!(email: params.fetch(:email))
    render json: { id: api_user.id }
  end

private

  def create_api_user(name:, email:)
    api_user = ApiUser.build(name:, email:)

    if api_user.invalid? && api_user.errors.where(:email, :taken).any?
      raise ActiveRecord::RecordNotUnique
    end

    api_user.save!
    api_user
  end

  def validate_create_params
    assert_no_missing_params(%i[
      name email
    ])
  end

  def validate_show_params
    assert_no_missing_params(%i[email])
  end
end
