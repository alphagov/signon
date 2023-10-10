module Doorkeeper
  class AccessGrant < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    include Models::ExpirationTimeSqlMath

    scope :expired, -> { where.not(expires_in: nil).where("#{sanitize_sql(expiration_time_sql)} < ?", Time.current) }
  end
end
