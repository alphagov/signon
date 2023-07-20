class TwoStepVerificationExemption
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :reason, :string
  attribute :expiry_day, :string
  attribute :expiry_month, :string
  attribute :expiry_year, :string

  attr_reader :expiry_date

  validates :reason, presence: { message: "must be provided" }
  validate :check_expiry_date

  def self.from_user(user)
    new(
      reason: user.reason_for_2sv_exemption,
      expiry_day: user.expiry_date_for_2sv_exemption&.day,
      expiry_month: user.expiry_date_for_2sv_exemption&.month,
      expiry_year: user.expiry_date_for_2sv_exemption&.year,
    )
  end

  def self.from_params(params)
    new(
      reason: params[:reason],
      expiry_day: params[:expiry_date][:day],
      expiry_month: params[:expiry_date][:month],
      expiry_year: params[:expiry_date][:year],
    )
  end

private

  def check_expiry_date
    if expiry_day.blank? && expiry_month.blank? && expiry_year.blank?
      errors.add(:expiry_date, "must be provided")
    elsif expiry_day.blank? || expiry_month.blank? || expiry_year.blank?
      errors.add(:expiry_date, "day must be provided") if expiry_day.blank?
      errors.add(:expiry_date, "month must be provided") if expiry_month.blank?
      errors.add(:expiry_date, "year must be provided") if expiry_year.blank?
    else
      @expiry_date = Date.parse("#{expiry_year}-#{expiry_month}-#{expiry_day}")
      errors.add(:expiry_date, "must be in the future") unless expiry_date > Time.zone.today
    end
  rescue Date::Error
    errors.add(:expiry_date, "must be a real date")
  end
end
