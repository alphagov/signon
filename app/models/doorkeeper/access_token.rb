module Doorkeeper
  class AccessToken < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    scope :not_revoked, -> { where(revoked_at: nil) }
    scope :expires_after, ->(time) { where.not(expires_in: nil).where("#{sanitize_sql(expiration_time_sql)} > ?", time) }
    scope :expires_before, ->(time) { where.not(expires_in: nil).where("#{sanitize_sql(expiration_time_sql)} < ?", time) }
    scope :expired, -> { where.not(expires_in: nil).where("#{sanitize_sql(expiration_time_sql)} < ?", Time.current) }
    scope :ordered_by_expires_at, -> { order(expiration_time_sql) }
    scope :ordered_by_application_name, -> { includes(:application).merge(Doorkeeper::Application.ordered_by_name) }
  end
end
