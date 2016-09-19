require 'rails_helper'

RSpec.describe UserPermissionMigrator do
  let(:specialist_publisher) { FactoryGirl.create(:application, name: "Specialist Publisher") }
  let(:manuals_publisher) { FactoryGirl.create(:application, name: "Manuals Publisher") }
  let(:unrelated_application) { FactoryGirl.create(:application, name: "unrelated application") }

  before do
    FactoryGirl.create(:supported_permission, application: specialist_publisher, name: "gds_editor")
    FactoryGirl.create(:supported_permission, application: specialist_publisher, name: "editor")

    FactoryGirl.create(:supported_permission, application: manuals_publisher, name: "gds_editor")
    FactoryGirl.create(:supported_permission, application: manuals_publisher, name: "editor")

    FactoryGirl.create(:supported_permission, application: unrelated_application, name: "gds_editor")
    FactoryGirl.create(:supported_permission, application: unrelated_application, name: "editor")
  end

  let!(:gds_editor) { FactoryGirl.create(:user, with_permissions: {"Specialist Publisher" => %w(editor gds_editor signin)}) }
  let!(:editor) { FactoryGirl.create(:user, with_permissions: {"Specialist Publisher" => %w(editor signin)}) }
  let!(:writer) { FactoryGirl.create(:user, with_permissions: {"Specialist Publisher" => %w(signin)}) }
  let!(:user_without_access) { FactoryGirl.create(:user) }
  let!(:user_with_unrelated_access) { FactoryGirl.create(:user, with_permissions: {"unrelated application" => %w(editor gds_editor signin)}) }

  it "copies permissions over for all users of an application to another application" do
    UserPermissionMigrator.migrate(
      source: "Specialist Publisher",
      target: "Manuals Publisher",
    )

    expect(gds_editor.permissions_for(manuals_publisher)).to eq %w(editor gds_editor signin)
    expect(editor.permissions_for(manuals_publisher)).to eq %w(editor signin)
    expect(writer.permissions_for(manuals_publisher)).to eq %w(signin)
    expect(user_without_access.permissions_for(manuals_publisher)).to eq []
    expect(user_with_unrelated_access.permissions_for(manuals_publisher)).to eq []

    expect(gds_editor.permissions_for(specialist_publisher)).to eq %w(editor gds_editor signin)
    expect(editor.permissions_for(specialist_publisher)).to eq %w(editor signin)
    expect(writer.permissions_for(specialist_publisher)).to eq %w(signin)
    expect(user_without_access.permissions_for(specialist_publisher)).to eq []
    expect(user_with_unrelated_access.permissions_for(specialist_publisher)).to eq []
  end
end
