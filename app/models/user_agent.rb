class UserAgent < ApplicationRecord
  validates :user_agent_string, presence: true
end
