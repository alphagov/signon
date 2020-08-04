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
        scope :active, -> { where("suspended_at" => nil) }
        scope :suspended, -> { where("suspended_at IS NOT NULL") }
        scope(:current, proc { |current| current == "t" ? active : suspended })
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

      # Return value is checked, so don't raise
      # error on validation failures
      # rubocop:disable Rails/SaveBang
      def suspend(reason)
        GovukStatsd.increment("users.suspend")
        update(reason_for_suspension: reason,
               suspended_at: Time.zone.now)
      end
      # rubocop:enable Rails/SaveBang

      def unsuspend
        update(password: SecureRandom.hex,
               unsuspended_at: Time.zone.now,
               suspended_at: nil,
               reason_for_suspension: nil)
      end

      def suspended?
        suspended_at.present?
      end
    end
  end
end
