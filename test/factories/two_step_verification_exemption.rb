FactoryBot.define do
  factory :two_step_verification_exemption do
    reason { "a very good reason" }
    expiry_day { Time.zone.tomorrow.day }
    expiry_month { Time.zone.tomorrow.month }
    expiry_year { Time.zone.tomorrow.year }
  end
end
