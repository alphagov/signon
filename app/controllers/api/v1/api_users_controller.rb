class Api::V1::ApiUsersController < Api::V1::ApiController
  before_action :validate_create_params, only: %w[create]
  before_action :validate_show_params, only: %w[show]

  def create
    api_user = create_api_user(name: params.fetch(:name), email: params.fetch(:email))
    render json: generate_response(api_user)
  end

  def show
    api_user = ApiUser.find_by!(email: params.fetch(:email))
    render json: generate_response(api_user)
  end

private

  def create_api_user(name:, email:)
    password = SecureRandom.urlsafe_base64
    api_user = ApiUser.new(name: name, email: email,
                           password: password, password_confirmation: password)
    api_user.skip_confirmation!
    api_user.api_user = true

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

  def generate_response(api_user)
    { api_user: { id: api_user.id.to_s, tokens: tokens(api_user) } }
  end

  def tokens(api_user)
    tokens = api_user.authorisations.joins(:application)
    tokens.map { |t| { token: t.token, application: t.application.name } }
  end
end
