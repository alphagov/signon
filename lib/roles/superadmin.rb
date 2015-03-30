module Roles
  class Superadmin

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation, :supported_permission_ids,
        :organisation_id, :unconfirmed_email, :confirmation_token,
        :role]
    end

    def self.role_name
      'superadmin'
    end

    def self.level; 0; end

    def self.manageable_roles
      User.roles
    end
  end
end
