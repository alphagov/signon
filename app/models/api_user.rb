class ApiUser < User
  default_scope { where(api_user: true).order(:name) }
  validate :reason_for_2sv_exemption_blank
  validate :require_2sv_is_false

  DEFAULT_TOKEN_LIFE = 2.years.to_i
  AUTOROTATABLE_TOKEN_LIFE = 60.days.to_i

private

  def require_2sv_is_false
    errors.add(:require_2sv, "can't be true for api user") if require_2sv
  end

  def reason_for_2sv_exemption_blank
    errors.add(:reason_for_2sv_exemption, "can't be present for api user") if exempt_from_2sv?
  end
end
