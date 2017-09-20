class UserAgent < ActiveRecord::Base
  validates_presence_of :user_agent_string
end
