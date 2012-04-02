module Devise
  module Models
    module Strengthened
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          validate :strong_enough_password?, :if => :password_required?
        end
      end

      protected

      def strong_enough_password?
        self.errors.add :password, :insufficient_entropy unless PassphraseEntropy.of(password) >= 20
      end

      module ClassMethods
        Devise::Models.config(self, :minimum_entropy)
      end
    end
  end
end
