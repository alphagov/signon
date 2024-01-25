module Roles
  class SuperOrganisationAdmin < Base
    def self.permitted_user_params
      [
        :uid,
        :name,
        :email,
        :password,
        :password_confirmation,
        :unconfirmed_email,
        :confirmation_token,
        :require_2sv,
        { supported_permission_ids: [] },
      ]
    end

    def self.role_name
      "super_organisation_admin"
    end

    def self.level
      2
    end

    def self.manageable_organisations_for(user)
      Organisation.where(id: user.organisation.subtree)
    end

    def self.require_2sv?
      true
    end
  end
end
