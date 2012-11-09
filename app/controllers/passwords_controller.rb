class PasswordsController < Devise::PasswordsController
  before_filter :record_password_reset_request, only: :create

  private
    def record_password_reset_request
      Statsd.new(::STATSD_HOST).increment(
        "#{::STATSD_PREFIX}.users.password_reset_request"
      )
    end
end
