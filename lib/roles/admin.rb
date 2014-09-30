module Roles
  class Admin

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation,
      :permissions_attributes, :organisation_id, :unconfirmed_email, :confirmation_token]
    end

    def self.role_name
      'admin'
    end

    def self.level; 1; end

    def self.manageable_roles
      %w{normal organisation_admin}
    end
  end
end
