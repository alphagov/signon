class UserAgent < ApplicationRecord
  validates_presence_of :user_agent_string
end
