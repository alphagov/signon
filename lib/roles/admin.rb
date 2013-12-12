module Roles
  class Admin

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation,
      :permissions_attributes, :organisation_id, :unconfirmed_email, :confirmation_token]
    end

    def self.name
      'admin'
    end

  end
end