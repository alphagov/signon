module Devise
  module Models
    module Suspendable
      extend ActiveSupport::Concern

      included do
        # active scope is returning all users, including those
        # where suspend_at = nil...
        # using User.not_suspended for now
        # TODO: work out why this scope is not working
        #       but the one in user model is.
        scope :active, -> { where('suspended_at' => nil) }
        scope :suspended, -> { where('suspended_at IS NOT NULL') }
        scope :current, proc { |current| current == 't' ? active : suspended }
      end

      def active_for_authentication?
        if super
          return true unless suspended?
          EventLog.record_event(self, EventLog::SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN)
        end
        false
      end

      def inactive_message
        suspended? ? :suspended : super
      end

      # Suspends the user in the database.
      def suspend(reason)
        self.reason_for_suspension = reason
        self.suspended_at = Time.zone.now
        GovukStatsd.increment("users.suspend")
        save
      end

      # un-suspends the user in the database.
      def unsuspend
        self.reason_for_suspension = nil
        self.suspended_at = nil
        self.unsuspended_at = Time.zone.now
        save
      end

      def suspended?
        suspended_at.present?
      end
    end
  end
end
