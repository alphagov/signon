module AdminApiHelper
private

  BEARER_TOKEN_VAR = "SIGNON_ADMIN_PASSWORD".freeze

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      if ENV.key? BEARER_TOKEN_VAR
        ActiveSupport::SecurityUtils.secure_compare(token, ENV.fetch(BEARER_TOKEN_VAR))
      end
    end
  end

  def missing_params_error(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def not_found_error(_exception)
    render json: { error: "Not found" }, status: :not_found
  end

  def not_valid_error(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def already_exists_error(_exception)
    render json: { error: "Record already exists" }, status: :bad_request
  end

  def assert_no_missing_params(required_params)
    missing = required_params
                .index_with { |key| params[key] }
                .select { |_k, v| v.blank? }
                .keys

    return if missing.empty?

    raise ActionController::ParameterMissing, missing.to_sentence
  end
end
