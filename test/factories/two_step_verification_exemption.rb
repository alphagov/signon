FactoryBot.define do
  factory :two_step_verification_exemption do
    reason { "a very good reason" }
    expiry_day { Time.zone.today.day + 1 }
    expiry_month { Time.zone.today.month }
    expiry_year { Time.zone.today.year }
  end
end
