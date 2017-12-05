require 'devise/hooks/password_expirable'

module Devise
  # How often should the password expire (e.g 3.months)
  mattr_accessor :expire_password_after
  self.expire_password_after = 3.months

  module Models
    module PasswordExpirable
      extend ActiveSupport::Concern

      included do
        before_save :update_password_changed

        scope :with_need_change_password, -> do
          if password_expires?
            where(arel_table[:password_changed_at].eq(nil).
              or(arel_table[:password_changed_at].lt(self.expire_password_after.ago)))
          end
        end

        scope :without_need_change_password, -> do
          if password_expires?
            where(arel_table[:password_changed_at].gteq(self.expire_password_after.ago))
          end
        end
      end

      def need_change_password?
        if self.class.password_expires?
          self.password_changed_at.nil? || self.password_changed_at < self.expire_password_after.ago
        else
          false
        end
      end

      def expire_password_after
        self.class.expire_password_after
      end

      private

      def update_password_changed
        self.password_changed_at = Time.zone.now if (self.new_record? || self.encrypted_password_changed?) && !self.password_changed_at_changed?
      end

      module ClassMethods
        ::Devise::Models.config(self, :expire_password_after)

        def password_expires?
          self.expire_password_after.is_a?(Integer) || self.expire_password_after.is_a?(Float)
        end
      end
    end
  end
end

Devise.add_module :password_expirable,
                  model: 'devise/models/password_expirable',
                  route: :password_expired,
                  controller: :password_expired
