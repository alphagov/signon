module Roles
  class Superadmin

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation,
        :permissions_attributes, :organisation_id, :unconfirmed_email, :confirmation_token,
        :role]
    end

    def self.role_name
      'superadmin'
    end

  end
end
