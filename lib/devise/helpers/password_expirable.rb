module Devise
  module Helpers
    module PasswordExpirable
      extend ActiveSupport::Concern

      included do
        before_action :handle_password_change
      end

      private

      # check if a password change needed
      def handle_password_change
        if not devise_controller? && !request.format.nil? && request.format.html?
          Devise.mappings.keys.flatten.any? do |scope|
            if signed_in?(scope) && warden.session(scope)['password_expired']
              # re-check to avoid infinite loop if date changed after login attempt
              if send(:"current_#{scope}").try(:need_change_password?)
                session["#{scope}_return_to"] = request.original_fullpath if request.get?
                redirect_for_password_change scope
                break
              else
                warden.session(scope)[:password_expired] = false
              end
            end
          end
        end
      end

      # redirect for password update with alert message
      def redirect_for_password_change(scope)
        redirect_to change_password_required_path_for(scope), alert: I18n.t('change_required', {scope: 'devise.password_expired'})
      end

      # path for change password
      def change_password_required_path_for(resource_or_scope = nil)
        scope       = Devise::Mapping.find_scope!(resource_or_scope)
        change_path = "#{scope}_password_expired_path"
        send(change_path)
      end
    end
  end
end
