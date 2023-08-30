FactoryBot.define do
  factory :event_log do
    event_id { EventLog::NO_SUCH_ACCOUNT_LOGIN.id }
    uid { create(:user).uid }
  end
end
