class ApiUser < User
  default_scope { where(api_user: true).order(:name) }

  validate :reason_for_2sv_exemption_blank
  validate :require_2sv_is_false

  DEFAULT_TOKEN_LIFE = 2.years.to_i

  def self.build(attributes = {})
    password = SecureRandom.urlsafe_base64
    new(attributes.merge(password:, password_confirmation: password)).tap do |u|
      u.skip_confirmation!
      u.api_user = true
    end
  end

  def self.for_sso_push
    name = "Signon API Client (permission and suspension updater)"
    email = "signon+permissions@alphagov.co.uk"
    find_by(email:) || build(name:, email:).tap(&:save!)
  end

  def self.for_background_job
    name = "Signon background job"
    email = "signon+job@alphagov.co.uk"
    find_by(email:) || build(name:, email:).tap(&:save!)
  end

  def self.for_rails_console
    name = "Signon rails console"
    email = "signon+rails@alphagov.co.uk"
    find_by(email:) || build(name:, email:).tap(&:save!)
  end

private

  def require_2sv_is_false
    errors.add(:require_2sv, "can't be true for api user") if require_2sv
  end

  def reason_for_2sv_exemption_blank
    errors.add(:reason_for_2sv_exemption, "can't be present for api user") if exempt_from_2sv?
  end
end
