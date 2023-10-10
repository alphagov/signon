module Doorkeeper
  class AccessToken < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    scope :not_revoked, -> { where(revoked_at: nil) }
    scope :expires_after, ->(time) { where.not(expires_in: nil).where("#{sanitize_sql(expiration_time_sql)} > ?", time) }
  end
end
