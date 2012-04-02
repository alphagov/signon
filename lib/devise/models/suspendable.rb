module Devise
  module Models

    module Suspendable
      extend ActiveSupport::Concern

      included do
        scope :active, where('suspended_at' => nil)
        scope :suspended, where('suspended_at IS NOT NULL')
        scope :current, proc { |current| current == 't' ? active : suspended }
      end
    
      def not_suspended?
        ! suspended?
      end
    
      if instance_methods.include?(:active?)
        def active?
          super && not_suspended?
        end
      else
        alias :active? :not_suspended?
      end
    
      def inactive_message
        !suspended? ? super : :suspended
      end
    
      # Suspends the user in the database.
      def suspend!
        self.suspended_at = Time.now.utc
        save!
      end
    
      # un-suspends the user in the database.
      def unsuspend!
        self.suspended_at = nil
        save!
      end
    
      def suspended?
        suspended_at.present?
      end
    end
  end
end
