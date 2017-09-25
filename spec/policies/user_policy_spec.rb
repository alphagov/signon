require 'rails_helper'

describe UserPolicy do
  subject { described_class }
  let(:parent_organisation)         { create(:organisation) }
  let(:child_organisation)          { create(:organisation, parent: parent_organisation) }
  let(:super_org_admin)             { create(:super_org_admin, organisation: parent_organisation) }
  let(:organisation_admin)          { create(:organisation_admin, organisation: parent_organisation) }

  primary_management_actions = [:new?, :assign_organisations?]
  user_management_actions = [:edit?, :create?, :update?, :unlock?, :suspension?, :cancel_email_change?, :resend_email_change?, :event_logs?]
  self_management_actions = [:edit_email_or_passphrase?, :update_email?, :update_passphrase?, :cancel_email_change?, :resend_email_change?]
  disallowed_actions_org_admin = [:create?, :assign_organisations?]
  disallowed_actions_super_org_admin = [:create?, :assign_organisations?]

  org_admin_actions = user_management_actions - disallowed_actions_org_admin
  super_org_admin_actions = user_management_actions - disallowed_actions_super_org_admin
  admin_actions = user_management_actions - self_management_actions
  superadmin_actions = [:assign_role?, :flag_2sv?, :reset_2sv?]

  context "for superadmins" do
    permissions :index? do
      it "is allowed for superadmins" do
        expect(subject).to permit(build(:superadmin_user), User)
      end
    end

    primary_management_actions.each do |permission|
      permissions permission do
        it "is allowed for superadmins" do
          expect(subject).to permit(build(:superadmin_user), User)
        end
      end
    end

    user_management_actions.each do |permission_name|
      permissions permission_name do
        it "is allowed for superadmins accessing any type of user" do
          superadmin = create(:superadmin_user)

          expect(subject).to permit(superadmin, build(:user))
          expect(subject).to permit(superadmin, build(:organisation_admin))
          expect(subject).to permit(superadmin, build(:super_org_admin))
          expect(subject).to permit(superadmin, build(:admin_user))
          expect(subject).to permit(superadmin, build(:superadmin_user))
        end
      end
    end

    superadmin_actions.each do |permission_name|
      permissions permission_name do
        it "is allowed only for superadmins" do
          expect(subject).to permit(create(:superadmin_user), User)
        end
      end
    end
  end

  context "for admins" do
    permissions :index? do
      it "is allowed for admins" do
        expect(subject).to permit(build(:admin_user), User)
      end
    end

    primary_management_actions.each do |permission|
      permissions permission do
        it "is allowed for admins" do
          expect(subject).to permit(build(:admin_user), User)
        end
      end
    end

    user_management_actions.each do |permission_name|
      permissions permission_name do
        it "is allowed for admins accessing users with equal or fewer priviledges" do
          admin = create(:admin_user)

          expect(subject).not_to permit(admin, build(:superadmin_user))
          expect(subject).to permit(admin, build(:admin_user))
          expect(subject).to permit(admin, build(:super_org_admin))
          expect(subject).to permit(admin, build(:organisation_admin))
          expect(subject).to permit(admin, build(:user))
        end
      end
    end

    superadmin_actions.each do |permission_name|
      permissions permission_name do
        it "is forbidden for admins" do
          expect(subject).not_to permit(create(:admin_user), User)
        end
      end
    end
  end

  context "for super organisation admins" do
    permissions :index? do
      it "is allowed for super organisation admins" do
        expect(subject).to permit(build(:super_org_admin), User)
      end
    end

    primary_management_actions.each do |permission|
      permissions permission do
        it "is forbidden for super organisation admins" do
          expect(subject).not_to permit(build(:super_org_admin), User)
        end
      end
    end

    disallowed_actions_super_org_admin.each do |disallowed_super_org_admin_permission|
      permissions disallowed_super_org_admin_permission do
        it "is forbidden for super organisation admins to create any type of user or assign organisations to them" do
          expect(subject).not_to permit(super_org_admin, build(:superadmin_user))
          expect(subject).not_to permit(super_org_admin, build(:admin_user))
          expect(subject).not_to permit(super_org_admin, build(:super_org_admin))
          expect(subject).not_to permit(super_org_admin, build(:organisation_admin))
          expect(subject).not_to permit(super_org_admin, build(:user_in_organisation))
          expect(subject).not_to permit(super_org_admin, build(:user_in_organisation, organisation: organisation_admin.organisation))
        end
      end
    end

    super_org_admin_actions.each do |allowed_super_org_admin_permission|
      permissions allowed_super_org_admin_permission do
        it "is allowed for super organisation admins to access users of similar permissions or below from within their own organisation" do
          expect(subject).to permit(super_org_admin, build(:user_in_organisation, organisation: super_org_admin.organisation))
          expect(subject).to permit(super_org_admin, build(:organisation_admin, organisation: super_org_admin.organisation))
          expect(subject).to permit(super_org_admin, build(:super_org_admin, organisation: super_org_admin.organisation))

          expect(subject).not_to permit(super_org_admin, build(:superadmin_user))
          expect(subject).not_to permit(super_org_admin, build(:admin_user))
        end

        it "is allowed for super organisation admins to access users of similar permissions or below from within their own organisation's subtree" do
          expect(subject).to permit(super_org_admin, build(:user_in_organisation, organisation: child_organisation))
          expect(subject).to permit(super_org_admin, build(:organisation_admin, organisation: child_organisation))
          expect(subject).to permit(super_org_admin, build(:super_org_admin, organisation: child_organisation))

          expect(subject).not_to permit(super_org_admin, build(:superadmin_user, organisation: child_organisation))
          expect(subject).not_to permit(super_org_admin, build(:admin_user, organisation: child_organisation))
        end

        it "is forbidden for super organisation admins to access users from other organisations" do
          expect(subject).not_to permit(super_org_admin, build(:user_in_organisation))
          expect(subject).not_to permit(super_org_admin, build(:organisation_admin))
          expect(subject).not_to permit(super_org_admin, build(:super_org_admin))
          expect(subject).not_to permit(super_org_admin, build(:superadmin_user))
          expect(subject).not_to permit(super_org_admin, build(:admin_user))
        end
      end
    end

    superadmin_actions.each do |permission_name|
      permissions permission_name do
        it "is forbidden for super organisation admins" do
          expect(subject).not_to permit(create(:super_org_admin), User)
        end
      end
    end
  end

  context "for organisation admins" do
    permissions :index? do
      it "is allowed for organisation admins" do
        expect(subject).to permit(build(:organisation_admin), User)
      end
    end

    primary_management_actions.each do |permission|
      permissions permission do
        it "is forbidden for organisation admins" do
          expect(subject).not_to permit(build(:organisation_admin), User)
        end
      end
    end

    disallowed_actions_org_admin.each do |disallowed_org_admin_permission|
      permissions disallowed_org_admin_permission do
        it "is forbidden for organisation admins to create any type of user or assign organisations to them" do
          expect(subject).not_to permit(organisation_admin, build(:superadmin_user))
          expect(subject).not_to permit(organisation_admin, build(:admin_user))
          expect(subject).not_to permit(organisation_admin, build(:super_org_admin))
          expect(subject).not_to permit(organisation_admin, build(:organisation_admin))
          expect(subject).not_to permit(organisation_admin, build(:user_in_organisation))
          expect(subject).not_to permit(organisation_admin, build(:user_in_organisation, organisation: organisation_admin.organisation))
        end
      end
    end

    org_admin_actions.each do |allowed_org_admin_permission|
      permissions allowed_org_admin_permission do
        it "is forbidden for organisation admins to access users of similar permissions or below from within their own organisation" do
          expect(subject).to permit(organisation_admin, build(:user_in_organisation, organisation: organisation_admin.organisation))
          expect(subject).to permit(organisation_admin, build(:organisation_admin, organisation: organisation_admin.organisation))

          expect(subject).not_to permit(organisation_admin, build(:super_org_admin, organisation: organisation_admin.organisation))
          expect(subject).not_to permit(organisation_admin, build(:superadmin_user))
          expect(subject).not_to permit(organisation_admin, build(:admin_user))
        end

        it "is allowed for organisation admins to access users from within their own organisation's subtree" do
          expect(subject).not_to permit(organisation_admin, build(:user_in_organisation, organisation: child_organisation))
          expect(subject).not_to permit(organisation_admin, build(:organisation_admin, organisation: child_organisation))
          expect(subject).not_to permit(organisation_admin, build(:super_org_admin, organisation: child_organisation))
          expect(subject).not_to permit(organisation_admin, build(:superadmin_user, organisation: child_organisation))
          expect(subject).not_to permit(organisation_admin, build(:admin_user, organisation: child_organisation))
        end

        it "is forbidden for organisation admins to access users from other organisations" do
          expect(subject).not_to permit(organisation_admin, build(:user_in_organisation))
          expect(subject).not_to permit(organisation_admin, build(:organisation_admin))
          expect(subject).not_to permit(organisation_admin, build(:super_org_admin))
          expect(subject).not_to permit(organisation_admin, build(:superadmin_user))
          expect(subject).not_to permit(organisation_admin, build(:admin_user))
        end
      end
    end

    superadmin_actions.each do |permission_name|
      permissions permission_name do
        it "is forbidden for organisation admins" do
          expect(subject).not_to permit(create(:organisation_admin), User)
        end
      end
    end
  end

  context "for normal users" do
    permissions :index? do
      it "is forbidden for normal users" do
        expect(subject).not_to permit(build(:user), User)
      end
    end

    primary_management_actions.each do |permission|
      permissions permission do
        it "is forbidden for normal users" do
          expect(subject).not_to permit(build(:user), User)
        end
      end
    end

    user_management_actions.each do |permission_name|
      permissions permission_name do
        it "is forbidden for normal users accessing other normal users" do
          normal_user = create(:user)
          expect(subject).not_to permit(normal_user, build(:user))
        end
      end
    end

    self_management_actions.each do |permission_name|
      permissions permission_name do
        it "is allowed for normal users accessing their own record" do
          normal_user = create(:user)
          expect(subject).to permit(normal_user, normal_user)
        end
      end
    end

    superadmin_actions.each do |permission_name|
      permissions permission_name do
        it "is forbidden for normal users" do
          expect(subject).not_to permit(create(:user), User)
        end
      end
    end

    # Users shouldn't be able to do admin-only things to themselves
    admin_actions.each do |permission_name|
      permissions permission_name do
        it "is not allowed for normal users accessing their own record" do
          normal_user = create(:user)
          expect(subject).not_to permit(normal_user, normal_user)
        end
      end
    end
  end

  describe described_class::Scope do
    let(:parent_organisation) { create(:organisation) }
    let(:child_organisation) { create(:organisation, parent: parent_organisation) }
    let(:other_organisation) { create(:organisation) }

    let!(:super_admin_in_org) { create(:superadmin_user, organisation: parent_organisation) }
    let!(:admin_in_org) { create(:admin_user, organisation: parent_organisation) }
    let!(:super_org_admin_in_org) { create(:super_org_admin, organisation: parent_organisation) }
    let!(:org_admin_in_org) { create(:organisation_admin, organisation: parent_organisation) }
    let!(:normal_user_in_org) { create(:user_in_organisation, organisation: parent_organisation) }

    let!(:super_admin_in_child_org) { create(:superadmin_user, organisation: child_organisation) }
    let!(:admin_in_child_org) { create(:admin_user, organisation: child_organisation) }
    let!(:super_org_admin_in_child_org) { create(:super_org_admin, organisation: child_organisation) }
    let!(:org_admin_in_child_org) { create(:organisation_admin, organisation: child_organisation) }
    let!(:normal_user_in_child_org) { create(:user_in_organisation, organisation: child_organisation) }

    let!(:super_admin_in_other_org) { create(:superadmin_user, organisation: other_organisation) }
    let!(:admin_in_other_org) { create(:admin_user, organisation: other_organisation) }
    let!(:super_org_admin_in_other_org) { create(:super_org_admin, organisation: other_organisation) }
    let!(:org_admin_in_other_org) { create(:organisation_admin, organisation: other_organisation) }
    let!(:normal_user_in_other_org) { create(:user_in_organisation, organisation: other_organisation) }

    let!(:api_user) { create(:api_user) }

    subject { described_class.new(user, User.all) }
    let(:resolved_scope) { subject.resolve }

    context 'for super admins' do
      let(:user) { create(:superadmin_user) }

      it 'includes all web users' do
        expect(resolved_scope).to include(super_admin_in_org)
        expect(resolved_scope).to include(admin_in_org)
        expect(resolved_scope).to include(super_org_admin_in_org)
        expect(resolved_scope).to include(org_admin_in_org)
        expect(resolved_scope).to include(normal_user_in_org)

        expect(resolved_scope).to include(super_admin_in_child_org)
        expect(resolved_scope).to include(admin_in_child_org)
        expect(resolved_scope).to include(super_org_admin_in_child_org)
        expect(resolved_scope).to include(org_admin_in_child_org)
        expect(resolved_scope).to include(normal_user_in_child_org)

        expect(resolved_scope).to include(super_admin_in_other_org)
        expect(resolved_scope).to include(admin_in_other_org)
        expect(resolved_scope).to include(super_org_admin_in_other_org)
        expect(resolved_scope).to include(org_admin_in_other_org)
        expect(resolved_scope).to include(normal_user_in_other_org)
      end

      it 'does not include api users' do
        expect(resolved_scope).not_to include(api_user)
      end
    end

    context 'for admins' do
      let(:user) { create(:admin_user) }

      it 'includes all web users of similar permissions or below belonging to their organisation' do
        expect(resolved_scope).not_to include(super_admin_in_org)
        expect(resolved_scope).to include(admin_in_org)
        expect(resolved_scope).to include(super_org_admin_in_org)
        expect(resolved_scope).to include(org_admin_in_org)
        expect(resolved_scope).to include(normal_user_in_org)
      end

      it 'includes all web users of similar permissions or below belonging to a child organisation' do
        expect(resolved_scope).not_to include(super_admin_in_child_org)
        expect(resolved_scope).to include(admin_in_child_org)
        expect(resolved_scope).to include(super_org_admin_in_child_org)
        expect(resolved_scope).to include(org_admin_in_child_org)
        expect(resolved_scope).to include(normal_user_in_child_org)
      end

      it 'includes all web users of similar permissions or below belonging to another organisation' do
        expect(resolved_scope).not_to include(super_admin_in_other_org)
        expect(resolved_scope).to include(admin_in_other_org)
        expect(resolved_scope).to include(super_org_admin_in_other_org)
        expect(resolved_scope).to include(org_admin_in_other_org)
        expect(resolved_scope).to include(normal_user_in_other_org)
      end

      it 'does not include api users' do
        expect(resolved_scope).not_to include(api_user)
      end
    end

    context 'for super organisation admins' do
      let(:user) { create(:super_org_admin, organisation: parent_organisation) }

      it 'includes users of similar permission or below belonging to their organisation' do
        expect(resolved_scope).not_to include(super_admin_in_org)
        expect(resolved_scope).not_to include(admin_in_org)
        expect(resolved_scope).to include(super_org_admin_in_org)
        expect(resolved_scope).to include(org_admin_in_org)
        expect(resolved_scope).to include(normal_user_in_org)
      end

      it 'includes users of similar permission or below belonging to a child organisation' do
        expect(resolved_scope).not_to include(super_admin_in_child_org)
        expect(resolved_scope).not_to include(admin_in_child_org)
        expect(resolved_scope).to include(super_org_admin_in_child_org)
        expect(resolved_scope).to include(org_admin_in_child_org)
        expect(resolved_scope).to include(normal_user_in_child_org)
      end

      it 'does not include users of similar permission or below belonging to another organisation' do
        expect(resolved_scope).not_to include(super_admin_in_other_org)
        expect(resolved_scope).not_to include(admin_in_other_org)
        expect(resolved_scope).not_to include(super_org_admin_in_other_org)
        expect(resolved_scope).not_to include(org_admin_in_other_org)
        expect(resolved_scope).not_to include(normal_user_in_other_org)
      end

      it 'does not include api users' do
        expect(resolved_scope).not_to include(api_user)
      end
    end

    context 'for organisation admins' do
      let(:user) { create(:organisation_admin, organisation: parent_organisation) }

      it 'includes users of similar permission or below belonging to their organisation' do
        expect(resolved_scope).not_to include(super_admin_in_org)
        expect(resolved_scope).not_to include(admin_in_org)
        expect(resolved_scope).not_to include(super_org_admin_in_org)
        expect(resolved_scope).to include(org_admin_in_org)
        expect(resolved_scope).to include(normal_user_in_org)
      end

      it 'does not include users of similar permission or below belonging to a child organisation' do
        expect(resolved_scope).not_to include(super_admin_in_child_org)
        expect(resolved_scope).not_to include(admin_in_child_org)
        expect(resolved_scope).not_to include(super_org_admin_in_child_org)
        expect(resolved_scope).not_to include(org_admin_in_child_org)
        expect(resolved_scope).not_to include(normal_user_in_child_org)
      end

      it 'does not include users of similar permission or below belonging to another organisation' do
        expect(resolved_scope).not_to include(super_admin_in_other_org)
        expect(resolved_scope).not_to include(admin_in_other_org)
        expect(resolved_scope).not_to include(super_org_admin_in_other_org)
        expect(resolved_scope).not_to include(org_admin_in_other_org)
        expect(resolved_scope).not_to include(normal_user_in_other_org)
      end

      it 'does not include api users' do
        expect(resolved_scope).not_to include(api_user)
      end
    end

    context 'for normal users' do
      let(:user) { create(:user) }

      it 'is empty' do
        expect(resolved_scope).to be_empty
      end
    end
  end
end
