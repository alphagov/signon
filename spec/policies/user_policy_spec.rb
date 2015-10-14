require 'rails_helper'

describe UserPolicy do
  subject { described_class }

  [:new?, :index?].each do |permission_name|
    permissions permission_name do
      it "is allowed for superadmins" do
        expect(subject).to permit(build(:superadmin_user), User)
      end

      it "is allowed for admins" do
        expect(subject).to permit(build(:admin_user), User)
      end

      it "is allowed for organisation admins" do
        expect(subject).to permit(build(:organisation_admin), User)
      end

      it "is forbidden for normal user" do
        expect(subject).not_to permit(build(:user), User)
      end
    end
  end

  user_management_actions = %i(
    edit?
    create?
    update?
    unlock?
    suspension?
    cancel_email_change?
    resend_email_change?
    event_logs?
  )

  user_management_actions.each do |permission_name|
    permissions permission_name do
      it "is allowed for superadmins accessing any type of user" do
        superadmin = create(:superadmin_user)

        expect(subject).to permit(superadmin, build(:user))
        expect(subject).to permit(superadmin, build(:organisation_admin))
        expect(subject).to permit(superadmin, build(:admin_user))
        expect(subject).to permit(superadmin, build(:superadmin_user))
      end

      it "is allowed for admins accessing users with equal or fewer priviledges" do
        admin = create(:admin_user)

        expect(subject).not_to permit(admin, build(:superadmin_user))
        expect(subject).to permit(admin, build(:admin_user))
        expect(subject).to permit(admin, build(:organisation_admin))
        expect(subject).to permit(admin, build(:user))
      end

      it "is allowed for organisation admins accessing normal users within their organisation" do
        organisation_admin = create(:organisation_admin)

        expect(subject).not_to permit(organisation_admin, build(:superadmin_user))
        expect(subject).not_to permit(organisation_admin, build(:admin_user))
        expect(subject).not_to permit(organisation_admin, build(:organisation_admin))
        expect(subject).not_to permit(organisation_admin, build(:user_in_organisation))

        expect(subject).to permit(organisation_admin, build(:user_in_organisation, organisation: organisation_admin.organisation))
      end

      it "is forbidden for normal users accessing other normal users" do
        normal_user = create(:user)
        expect(subject).not_to permit(normal_user, build(:user))
      end
    end
  end

  self_management_actions = [:edit_email_or_passphrase?, :update_email?, :update_passphrase?, :cancel_email_change?, :resend_email_change?]
  self_management_actions.each do |permission_name|
    permissions permission_name do
      it "is allowed for normal users accessing their own record" do
        normal_user = create(:user)
        expect(subject).to permit(normal_user, normal_user)
      end
    end
  end

  # Users shouldn't be able to do admin-only things to themselves
  (user_management_actions - self_management_actions).each do |permission_name|
    permissions permission_name do
      it "is not allowed for normal users accessing their own record" do
        normal_user = create(:user)
        expect(subject).not_to permit(normal_user, normal_user)
      end
    end
  end

  permissions :assign_role? do
    it "is allowed only for superadmins" do
      expect(subject).to permit(create(:superadmin_user), User)

      expect(subject).not_to permit(create(:admin_user), User)
      expect(subject).not_to permit(create(:organisation_admin), User)
      expect(subject).not_to permit(create(:user), User)
    end
  end

  permissions :flag_2sv? do
    it "is only allowed for superadmins" do
      expect(subject).to permit(build(:superadmin_user), User)

      expect(subject).not_to permit(create(:admin_user), User)
      expect(subject).not_to permit(create(:organisation_admin), User)
      expect(subject).not_to permit(create(:user), User)
    end
  end

  permissions :reset_2sv? do
    it "is only allowed for superadmins" do
      expect(subject).to permit(build(:superadmin_user), User)

      expect(subject).not_to permit(create(:admin_user), User)
      expect(subject).not_to permit(create(:organisation_admin), User)
      expect(subject).not_to permit(create(:user), User)
    end
  end
end
